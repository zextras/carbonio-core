#!/usr/bin/perl

# SPDX-FileCopyrightText: 2026 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

=head1 NAME

contactbackup-schedule - manage the contact backup systemd timers (CO-2512)

=head1 SYNOPSIS

contactbackup-schedule convert "<min hour dom mon dow>"

contactbackup-schedule list

contactbackup-schedule add "<min hour dom mon dow>" <-l | server...>

contactbackup-schedule default <server>

contactbackup-schedule flush

contactbackup-schedule migrate

=head1 DESCRIPTION

Backend of C<zmcontactbackup> (-a/-d/-f/-q) on the hosts that use systemd
timers instead of the zextras crontab. Every schedule is one instance
C<N> of the packaged templates C<carbonio-contact-backup@.timer> and
C<carbonio-contact-backup@.service>. The helper writes two drop-ins, which
carry everything that differs between instances:

  /etc/systemd/system/carbonio-contact-backup@N.timer.d/schedule.conf
  /etc/systemd/system/carbonio-contact-backup@N.service.d/servers.conf

and enables the timer. The original crontab-style specifier and the server
list are kept in the timer drop-in (C<X-ContactBackup-*> keys), so C<list>
reports them exactly as the user typed them.

C<add>, C<default>, C<flush> and C<migrate> change systemd units, so they
need root: zextras runs them through sudo. Because that makes this script
a privilege boundary, every argument is validated against a strict grammar
before it is used, nothing is passed to a shell, and the only files touched
are the C<carbonio-contact-backup@N.*.d> directories (N numeric) of
/etc/systemd/system. C<convert> and C<list> are read-only and run as any
user.

=head2 Cron to OnCalendar

The five fields accept C<*>, lists, ranges, C<*/n> and C<a-b/n>, month and
weekday names, and 7 as Sunday. Every field is expanded to the explicit
set of values. Like cron, when both day of month and day of week are
restricted (neither starts with C<*>) the job runs when either matches:
two C<OnCalendar=> lines are produced, systemd ORs them. Every expression
is checked with C<systemd-analyze calendar> before it is used.

=cut

use strict;
use warnings;
use Fcntl qw(:flock);

$ENV{PATH} = '/usr/sbin:/usr/bin:/sbin:/bin';
umask 022;

my $UNIT_DIR     = '/etc/systemd/system';
my $PREFIX       = 'carbonio-contact-backup';
my $LOCK_FILE    = '/run/carbonio-contact-backup-schedule.lock';
my $SYSTEMCTL    = '/usr/bin/systemctl';
my $ANALYZE      = '/usr/bin/systemd-analyze';
my $CRONTAB      = '/usr/bin/crontab';
my $DEFAULT_CRON = '0 3 * * *';
my $MAX_SERVERS  = 64;

my %MONTH = (
    jan => 1, feb => 2,  mar => 3,  apr => 4,
    may => 5, jun => 6,  jul => 7,  aug => 8,
    sep => 9, oct => 10, nov => 11, dec => 12,
);
my %WEEKDAY = ( sun => 0, mon => 1, tue => 2, wed => 3, thu => 4, fri => 5, sat => 6 );
my @WEEKDAY_NAME = qw(Sun Mon Tue Wed Thu Fri Sat);

###### cron -> OnCalendar ######

# Value of one token of a field: a number or, where allowed, a name.
sub field_value {
    my ( $token, $names ) = @_;
    return $token + 0 if $token =~ /^\d{1,2}$/;
    return $names->{ lc $token } if $names && exists $names->{ lc $token };
    die "invalid value '$token'\n";
}

# Parse one cron field into ( \@sorted_values, $starts_with_star ).
sub parse_field {
    my ( $field, $label, $min, $max, $names ) = @_;
    die "$label: empty field\n" if !defined $field || $field eq '';
    my %set;
    foreach my $item ( split( /,/, $field, -1 ) ) {
        $item =~ m{^(\*|([0-9A-Za-z]+)(?:-([0-9A-Za-z]+))?)(?:/(\d+))?$}
          or die "$label: invalid item '$item'\n";
        my ( $whole, $lo_tok, $hi_tok, $step ) = ( $1, $2, $3, $4 );
        my ( $lo, $hi );
        if ( $whole eq '*' ) {
            ( $lo, $hi ) = ( $min, $max );
        }
        elsif ( defined $hi_tok ) {
            $lo = eval { field_value( $lo_tok, $names ) };
            $hi = eval { field_value( $hi_tok, $names ) };
            die "$label: invalid range '$whole'\n" if !defined $lo || !defined $hi;
        }
        else {
            die "$label: a step needs * or a range: '$item'\n" if defined $step;
            $lo = $hi = eval { field_value( $lo_tok, $names ) };
            die "$label: invalid value '$lo_tok'\n" if !defined $lo;
        }
        die "$label: '$item' out of range $min-$max\n"
          if $lo < $min || $hi > $max;
        die "$label: reversed range '$item'\n" if $lo > $hi;
        if ( defined $step ) {
            die "$label: step must be at least 1: '$item'\n" if $step < 1;
        }
        else {
            $step = 1;
        }
        for ( my $v = $lo ; $v <= $hi ; $v += $step ) {
            $set{$v} = 1;
        }
    }
    return ( [ sort { $a <=> $b } keys %set ], substr( $field, 0, 1 ) eq '*' );
}

# systemd component for a set of values: * when it is the whole range.
sub component {
    my ( $values, $min, $max, $format ) = @_;
    return '*' if @$values == $max - $min + 1;
    return join( ',', map { $format->($_) } @$values );
}

sub split_spec {
    my $spec = shift;
    die "schedule must have 5 fields (minute hour day-of-month month day-of-week)\n"
      if !defined $spec || length($spec) > 200;
    die "schedule has characters cron does not accept\n"
      if $spec !~ m{^[0-9A-Za-z*,/\- \t]+$};
    my @f = split( /[ \t]+/, $spec );
    shift @f if @f && $f[0] eq '';
    die "schedule must have 5 fields (minute hour day-of-month month day-of-week)\n"
      if @f != 5;
    return @f;
}

# Returns the list of OnCalendar= expressions of a cron specifier.
sub cron_to_oncalendar {
    my $spec = shift;
    my ( $fmin, $fhour, $fdom, $fmon, $fdow ) = split_spec($spec);
    my ($min)        = parse_field( $fmin,  'minute',       0, 59 );
    my ($hour)       = parse_field( $fhour, 'hour',         0, 23 );
    my ( $dom, $dom_star ) = parse_field( $fdom, 'day of month', 1, 31 );
    my ($mon)        = parse_field( $fmon,  'month',        1, 12, \%MONTH );
    my ( $dow7, $dow_star ) = parse_field( $fdow, 'day of week', 0, 7, \%WEEKDAY );

    # 7 is Sunday too
    my %dow = map { ( $_ % 7 ) => 1 } @$dow7;
    my $dow = [ sort { $a <=> $b } keys %dow ];

    my $num = sub { $_[0] };
    my $time =
        component( $hour, 0, 23, $num ) . ':'
      . component( $min, 0, 59, $num ) . ':00';
    my $month   = component( $mon, 1,  12, $num );
    my $days    = component( $dom, 1,  31, $num );
    my $weekday = component( $dow, 0,  6,  sub { $WEEKDAY_NAME[ $_[0] ] } );

    # Both restricted: cron runs when either matches (day-of-month OR
    # day-of-week), systemd needs both to match inside one line.
    if ( !$dom_star && !$dow_star ) {
        return (
            "*-$month-$days $time",
            ( $weekday eq '*' ? '' : "$weekday " ) . "*-$month-* $time",
        );
    }
    return ( ( $weekday eq '*' ? '' : "$weekday " ) . "*-$month-$days $time" );
}

# Run a command without a shell; returns ( exit status, combined output ).
sub run_command {
    my @cmd = @_;
    pipe( my $rd, my $wr ) or die "pipe: $!\n";
    my $pid = fork();
    die "fork: $!\n" if !defined $pid;
    if ( !$pid ) {
        close $rd;
        open( STDIN,  '<', '/dev/null' );
        open( STDOUT, '>&', $wr ) or exit 127;
        open( STDERR, '>&', $wr ) or exit 127;
        exec(@cmd) or do { print STDERR "cannot run $cmd[0]: $!\n"; exit 127 };
    }
    close $wr;
    my $out = do { local $/; <$rd> };
    close $rd;
    waitpid( $pid, 0 );
    return ( $? >> 8, defined $out ? $out : '' );
}

# Converts and validates with systemd-analyze; dies with a message.
sub oncalendar_checked {
    my $spec = shift;
    my @lines = cron_to_oncalendar($spec);
    die "systemd-analyze not found\n" if !-x $ANALYZE;
    foreach my $line (@lines) {
        my ( $rc, $out ) = run_command( $ANALYZE, 'calendar', '--', $line );
        if ($rc) {
            $out =~ s/\s+$//;
            die "systemd rejects '$line' (from '$spec'): $out\n";
        }
    }
    return @lines;
}

###### arguments ######

sub valid_server {
    my $s = shift;
    return length($s) <= 253
      && $s =~ /^[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?$/;
}

# Servers of "add": -l (all) or a list of names. Returns the list, empty
# for all. Dies on anything else.
sub parse_servers {
    my @args = @_;
    if ( @args == 1 && $args[0] eq '-l' ) {
        return ();
    }
    die "expected -l or at least one server name\n" if !@args;
    die "too many servers\n" if @args > $MAX_SERVERS;
    foreach my $s (@args) {
        die "invalid server name '$s'\n" if !valid_server($s);
    }
    return @args;
}

###### instances ######

sub instance_ids {
    my %ids;
    opendir( my $dh, $UNIT_DIR ) or die "cannot read $UNIT_DIR: $!\n";
    foreach my $e ( readdir $dh ) {
        $ids{$1} = 1 if $e =~ /^\Q$PREFIX\E\@([0-9]{1,6})\.(?:timer|service)\.d$/;
    }
    closedir $dh;
    return sort { $a <=> $b } keys %ids;
}

sub timer_dropin  { return "$UNIT_DIR/$PREFIX\@$_[0].timer.d/schedule.conf" }
sub service_dropin { return "$UNIT_DIR/$PREFIX\@$_[0].service.d/servers.conf" }

# ( spec, servers-as-a-string ) of an instance, or undef when it has no
# readable drop-in.
sub read_instance {
    my $id = shift;
    open( my $fh, '<', timer_dropin($id) ) or return;
    my ( $spec, $servers );
    while ( my $l = <$fh> ) {
        $spec    = $1 if $l =~ /^X-ContactBackup-Schedule=(.*)$/;
        $servers = $1 if $l =~ /^X-ContactBackup-Servers=(.*)$/;
    }
    close $fh;
    return if !defined $spec;
    return ( $spec, defined $servers ? $servers : '' );
}

sub write_file {
    my ( $path, $content ) = @_;
    my $tmp = "$path.tmp$$";
    open( my $fh, '>', $tmp ) or die "cannot write $tmp: $!\n";
    print $fh $content;
    close $fh or die "cannot write $tmp: $!\n";
    rename( $tmp, $path ) or die "cannot rename $tmp: $!\n";
}

sub systemd_running { return -d '/run/systemd/system' }

sub systemctl {
    my @args = @_;
    my ( $rc, $out ) = run_command( $SYSTEMCTL, @args );
    if ($rc) {
        $out =~ s/\s+$//;
        die "systemctl @args failed: $out\n";
    }
}

sub daemon_reload {
    systemctl('daemon-reload') if systemd_running();
}

sub remove_instance_files {
    my $id = shift;
    foreach my $kind (qw(timer service)) {
        my $dir = "$UNIT_DIR/$PREFIX\@$id.$kind.d";
        foreach my $f ( glob("$dir/*") ) {
            unlink $f;
        }
        rmdir $dir;
    }
}

sub disable_instance {
    my $id    = shift;
    my $timer = "$PREFIX\@$id.timer";
    systemctl( 'disable', $timer );
    systemctl( 'stop',    $timer ) if systemd_running();
}

sub lock_exclusive {
    open( my $lock, '>', $LOCK_FILE ) or die "cannot open $LOCK_FILE: $!\n";
    flock( $lock, LOCK_EX ) or die "cannot lock $LOCK_FILE: $!\n";
    return $lock;
}

sub add_schedule {
    my ( $spec, @servers ) = @_;
    my @calendar = oncalendar_checked($spec);
    my $servers  = join( ' ', @servers );
    my $what     = "$spec " . ( @servers ? $servers : '(all servers)' );

    my @ids = instance_ids();
    my $id  = ( @ids ? $ids[-1] : 0 ) + 1;
    die "too many contact backup schedules\n" if $id > 999999;

    my $tdir = "$UNIT_DIR/$PREFIX\@$id.timer.d";
    my $sdir = "$UNIT_DIR/$PREFIX\@$id.service.d";
    my $ok   = eval {
        mkdir $tdir or die "cannot create $tdir: $!\n";
        mkdir $sdir or die "cannot create $sdir: $!\n";
        write_file( timer_dropin($id),
                "# Written by zmcontactbackup, do not edit.\n"
              . "[Unit]\n"
              . "Description=Carbonio contact backup $what\n"
              . "X-ContactBackup-Schedule=$spec\n"
              . "X-ContactBackup-Servers=$servers\n"
              . "[Timer]\n"
              . join( '', map { "OnCalendar=$_\n" } @calendar ) );
        write_file( service_dropin($id),
                "# Written by zmcontactbackup, do not edit.\n"
              . "[Unit]\n"
              . "Description=Carbonio contact backup $what\n"
              . "[Service]\n"
              . "Environment=CONTACT_BACKUP_SERVERS="
              . ( @servers ? $servers : '-l' )
              . "\n" );
        daemon_reload();
        systemctl( 'enable', "$PREFIX\@$id.timer" );
        systemctl( 'start',  "$PREFIX\@$id.timer" ) if systemd_running();
        1;
    };
    if ( !$ok ) {
        my $err = $@;
        remove_instance_files($id);
        eval { daemon_reload() };
        die $err;
    }
    return $id;
}

sub flush_schedules {
    my $failed = '';
    foreach my $id ( instance_ids() ) {
        eval { disable_instance($id); 1 } or $failed .= $@;
        remove_instance_files($id);
    }
    daemon_reload();
    die $failed if $failed ne '';
}

###### migration of the crontab block ######

# Schedule and servers of an entry written by the crontab version of
# zmcontactbackup; undef for anything else.
sub parse_cron_entry {
    my $line = shift;
    $line =~ s/\s+$//;
    $line =~ m{^\s*(\S+(?:\s+\S+){4})\s+(?:/opt/zextras/bin/)?zmsoap\s+-z\s+ContactBackupRequest\s+\@op=start(.*)$}
      or return;
    my ( $spec, $rest ) = ( $1, $2 );
    my @servers = $rest =~ m{\s(?:\.\./|servers\s+)?server=(\S+)\s+\@by=name(?=\s|$)}g;
    ( my $left = $rest ) =~ s/\s+servers(?=\s)//;
    $left =~ s{\s+(?:\.\./)?server=\S+\s+\@by=name}{}g;
    return if $left =~ /\S/;
    return if @servers > $MAX_SERVERS;
    foreach my $s (@servers) {
        return if !valid_server($s);
    }
    return ( $spec, @servers );
}

sub migrate_crontab {
    if ( !-x $CRONTAB ) {
        return;
    }
    my ( $rc, $out ) = run_command( $CRONTAB, '-u', 'zextras', '-l' );
    return if $rc;    # no crontab
    my @lines = split( /^/m, $out );

    my ( $begin, $end ) = ( -1, -1 );
    for ( my $i = 0 ; $i <= $#lines ; $i++ ) {
        if ( $begin < 0 && $lines[$i] =~ /^#\s*CONTACT BACKUP BEGIN/ ) {
            $begin = $i;
        }
        elsif ( $begin >= 0 && $lines[$i] =~ /^#\s*CONTACT BACKUP END/ ) {
            $end = $i;
            last;
        }
    }
    return if $begin < 0 || $end < 0;

    my %existing = map {
        my @i = read_instance($_);
        ( @i ? ( "$i[0]\n$i[1]" => 1 ) : () )
    } instance_ids();

    my ( @keep, $moved );
    foreach my $i ( $begin + 1 .. $end - 1 ) {
        my $line = $lines[$i];
        if ( $line =~ /^\s*(?:#|$)/ ) {
            push @keep, $line;
            next;
        }
        my ( $spec, @servers ) = parse_cron_entry($line);
        my $done = 0;
        if ( defined $spec ) {
            my $key = join( ' ', split( /\s+/, $spec ) );
            $key .= "\n" . join( ' ', @servers );
            if ( $existing{$key} ) {
                $done = 1;
            }
            elsif ( eval { add_schedule( join( ' ', split( /\s+/, $spec ) ), @servers ); 1 } ) {
                $existing{$key} = 1;
                $done = 1;
            }
            else {
                print STDERR "zmcontactbackup: cannot convert the crontab entry, "
                  . "it stays in the zextras crontab: $@";
            }
        }
        else {
            print STDERR "zmcontactbackup: crontab entry is not one zmcontactbackup wrote, "
              . "it stays in the zextras crontab and must be converted by hand: $line";
        }
        if ($done) {
            $moved++;
        }
        else {
            push @keep, $line;
        }
    }
    # The block stays only while it still holds an entry we could not convert.
    my $pending = grep { /\S/ && !/^\s*#/ } @keep;
    return if $pending && !$moved;
    my @new = @lines[ 0 .. $begin - 1 ];
    if ($pending) {
        push @new, $lines[$begin], @keep, $lines[$end];
    }
    push @new, @lines[ $end + 1 .. $#lines ];

    # Comments only (the empty block wrapper) count as an empty crontab.
    if ( grep { /\S/ && !/^\s*#/ } @new ) {
        open( my $fh, '|-', $CRONTAB, '-u', 'zextras', '-' )
          or die "cannot run crontab: $!\n";
        print $fh @new;
        close $fh or die "crontab -u zextras failed\n";
    }
    else {
        my ( $rrc, $rout ) = run_command( $CRONTAB, '-u', 'zextras', '-r' );
        die "crontab -r failed: $rout" if $rrc;
    }
    print "zmcontactbackup: moved $moved contact backup schedule(s) "
      . "from the zextras crontab to systemd timers\n"
      if $moved;
}

###### main ######

sub need_root {
    die "must run as root (use sudo)\n" if $< != 0;
}

sub usage {
    die "usage: $0 convert <schedule> | list | add <schedule> <-l|server...> | "
      . "default <server> | flush | migrate\n";
}

my ( $cmd, @args ) = @ARGV;
usage() if !defined $cmd;

my $status = eval {
    if ( $cmd eq 'convert' ) {
        usage() if @args != 1;
        print "$_\n" foreach oncalendar_checked( $args[0] );
    }
    elsif ( $cmd eq 'list' ) {
        usage() if @args;
        foreach my $id ( instance_ids() ) {
            my ( $spec, $servers ) = read_instance($id);
            print "$spec\t$servers\n" if defined $spec;
        }
    }
    elsif ( $cmd eq 'add' ) {
        usage() if @args < 2;
        need_root();
        my ( $spec, @rest ) = @args;
        my @servers = parse_servers(@rest);
        my $norm    = join( ' ', split_spec($spec) );
        my $lock    = lock_exclusive();
        add_schedule( $norm, @servers );
    }
    elsif ( $cmd eq 'default' ) {
        usage() if @args != 1;
        need_root();
        my @servers = parse_servers(@args);
        oncalendar_checked($DEFAULT_CRON);
        my $lock = lock_exclusive();
        flush_schedules();
        add_schedule( $DEFAULT_CRON, @servers );
    }
    elsif ( $cmd eq 'flush' ) {
        usage() if @args;
        need_root();
        my $lock = lock_exclusive();
        flush_schedules();
    }
    elsif ( $cmd eq 'migrate' ) {
        usage() if @args;
        need_root();
        my $lock = lock_exclusive();
        migrate_crontab();
    }
    else {
        usage();
    }
    1;
};
if ( !$status ) {
    my $err = $@;
    print STDERR "contactbackup-schedule: $err";
    exit 1;
}
exit 0;
