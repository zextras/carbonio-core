#!/usr/bin/perl

# SPDX-FileCopyrightText: 2026 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

# Harness for the cron to OnCalendar conversion of
# src/libexec/contactbackup-schedule.pl (CO-2512). Needs systemd-analyze.
#
#   perl tests/contactbackup-schedule.t
#
# 1. A table of specifiers with the exact expression(s) expected, and of
#    invalid ones that must be refused with a message.
# 2. Every valid specifier is run through `systemd-analyze calendar` (the
#    helper does it too, a failure there fails `convert`).
# 3. The firing times systemd computes are compared with a reference cron
#    matcher walking minute by minute over 400 days.

use strict;
use warnings;
use File::Basename qw(dirname);
use Test::More;

my $helper = dirname(__FILE__) . '/../src/libexec/contactbackup-schedule.pl';
my $analyze = '/usr/bin/systemd-analyze';
plan skip_all => 'systemd-analyze not available' if !-x $analyze;

$ENV{TZ} = 'UTC';

sub convert {
    my $spec = shift;
    open( my $fh, '-|', $^X, $helper, 'convert', $spec ) or die "run: $!";
    my @out = <$fh>;
    close $fh;
    chomp @out;
    return ( $? >> 8, @out );
}

# spec => [ expected OnCalendar lines ]
my @valid = (
    [ '0 1 * * *',                 ['*-*-* 1:0:00'] ],
    [ '0 3 * * *',                 ['*-*-* 3:0:00'] ],
    [ '*/15 2-4 * * mon-fri',      ['Mon,Tue,Wed,Thu,Fri *-*-* 2,3,4:0,15,30,45:00'] ],
    [ '* * * * *',                 ['*-*-* *:*:00'] ],
    [ '5,35 8-18/5 * * *',         ['*-*-* 8,13,18:5,35:00'] ],
    [ '0 0 1 * *',                 ['*-*-1 0:0:00'] ],
    [ '0 0 * * 0',                 ['Sun *-*-* 0:0:00'] ],
    [ '0 0 * * 7',                 ['Sun *-*-* 0:0:00'] ],
    [ '0 0 * * 0,7',               ['Sun *-*-* 0:0:00'] ],
    [ '0 0 * * sun',               ['Sun *-*-* 0:0:00'] ],
    [ '0 0 * * SAT,Sun',           ['Sun,Sat *-*-* 0:0:00'] ],
    [ '0 0 * * 1-5/2',             ['Mon,Wed,Fri *-*-* 0:0:00'] ],
    [ '0 0 * * */2',               ['Sun,Tue,Thu,Sat *-*-* 0:0:00'] ],
    [ '30 4 * jan-mar,dec *',      ['*-1,2,3,12-* 4:30:00'] ],
    [ '30 4 15 6 *',               ['*-6-15 4:30:00'] ],
    [ '0 */7 * * *',               ['*-*-* 0,7,14,21:0:00'] ],
    [ '00 03 * * *',               ['*-*-* 3:0:00'] ],
    [ "0\t1  *\t* *",              ['*-*-* 1:0:00'] ],
    # day of month and day of week both restricted: cron ORs them
    [ '0 3 1,15 * mon', [ '*-*-1,15 3:0:00', 'Mon *-*-* 3:0:00' ] ],
    [ '0 3 13 * 5',     [ '*-*-13 3:0:00',   'Fri *-*-* 3:0:00' ] ],
    # a field starting with * makes cron AND them
    [ '0 3 */2 * 1',    ['Mon *-*-1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31 3:0:00'] ],
    [ '0 3 1-7 * *',    ['*-*-1,2,3,4,5,6,7 3:0:00'] ],
);

my @invalid = (
    '',
    '0 1 * *',
    '0 1 * * * *',
    '@daily',
    '@reboot',
    '60 * * * *',
    '* 24 * * *',
    '* * 0 * *',
    '* * 32 * *',
    '* * * 0 *',
    '* * * 13 *',
    '* * * * 8',
    '5/15 * * * *',
    '*/0 * * * *',
    '*/x * * * *',
    '1-0 * * * *',
    'sat-sun * * * *',
    '* * * * mon-xyz',
    '* * * foo *',
    '0,,5 * * * *',
    '0 1 * * * ; id',
    '0 1 * * $(id)',
    "0 1 * * *\n0 2 * * *",
    '-5 * * * *',
    '1- * * * *',
    '0 1 * * *' . ( ' ' x 300 ),
);

foreach my $case (@valid) {
    my ( $spec, $expected ) = @$case;
    ( my $name = $spec ) =~ s/\s+/ /g;
    my ( $rc, @out ) = convert($spec);
    is( $rc, 0, "accepted: '$name'" );
    is_deeply( \@out, $expected, "converted: '$name'" );
}

foreach my $spec (@invalid) {
    ( my $name = substr( $spec, 0, 40 ) ) =~ s/\s+/ /g;
    $name =~ s/\n/\\n/g;
    my ( $rc, @out ) = convert($spec);
    isnt( $rc, 0, "refused: '$name'" );
    is( scalar(@out), 0, "nothing printed for '$name'" );
}

# Reference cron matcher, independent of the helper's field parser.
sub cron_set {
    my ( $field, $lo, $hi, $names ) = @_;
    my %set;
    foreach my $item ( split /,/, $field ) {
        my ( $range, $step ) = split m{/}, $item;
        $step ||= 1;
        my ( $a, $b );
        if ( $range eq '*' ) { ( $a, $b ) = ( $lo, $hi ) }
        elsif ( $range =~ /^(\w+)-(\w+)$/ ) { ( $a, $b ) = ( $names->{ lc $1 } // $1, $names->{ lc $2 } // $2 ) }
        else { $a = $b = $names->{ lc $range } // $range }
        for ( my $v = $a ; $v <= $b ; $v += $step ) { $set{$v} = 1 }
    }
    return \%set;
}

my %mon = ( jan => 1, feb => 2, mar => 3, apr => 4, may => 5, jun => 6, jul => 7, aug => 8, sep => 9, oct => 10, nov => 11, dec => 12 );
my %dow = ( sun => 0, mon => 1, tue => 2, wed => 3, thu => 4, fri => 5, sat => 6 );

# Epoch-free calendar walk: returns "YYYY-MM-DD HH:MM" strings of the
# minutes a spec fires in [base, base + 400 days).
sub cron_fires {
    my ($spec) = @_;
    my ( $fm, $fh, $fd, $fo, $fw ) = split ' ', $spec;
    my $min = cron_set( $fm, 0, 59 );
    my $hr  = cron_set( $fh, 0, 23 );
    my $dm  = cron_set( $fd, 1, 31 );
    my $mo  = cron_set( $fo, 1, 12, \%mon );
    my $wd  = cron_set( $fw, 0, 7,  \%dow );
    $wd->{0} = 1 if $wd->{7};
    my $star = ( $fd =~ /^\*/ || $fw =~ /^\*/ );
    my @out;
    my $t = 1767225600;    # 2026-01-01 00:00:00 UTC
    for my $day ( 0 .. 399 ) {
        my @g = gmtime( $t + $day * 86400 );
        my ( $d, $m, $y, $w ) = ( $g[3], $g[4] + 1, $g[5] + 1900, $g[6] );
        next if !$mo->{$m};
        my $dayok = $star ? ( $dm->{$d} && $wd->{$w} ) : ( $dm->{$d} || $wd->{$w} );
        next if !$dayok;
        foreach my $h ( sort { $a <=> $b } keys %$hr ) {
            foreach my $mi ( sort { $a <=> $b } keys %$min ) {
                push @out, sprintf( '%04d-%02d-%02d %02d:%02d', $y, $m, $d, $h, $mi );
            }
        }
    }
    # systemd's first elapse is strictly after the base time
    return grep { $_ ne '2026-01-01 00:00' } @out;
}

# Firing times systemd computes for one expression: first $n of them.
sub systemd_fires {
    my ( $expr, $n ) = @_;
    open( my $fh, '-|', $analyze, 'calendar', '--base-time=2026-01-01 00:00:00 UTC', "--iterations=$n", '--', $expr )
      or die "run: $!";
    my @t;
    while (<$fh>) {
        push @t, "$1 $2" if /(?:Next elapse|Iteration #\d+):\s+\w+ (\d{4}-\d\d-\d\d) (\d\d:\d\d):\d\d/;
    }
    close $fh;
    return @t;
}

my @semantic = (
    '0 1 * * *', '*/15 2-4 * * mon-fri', '5,35 8-18/5 * * *', '0 0 * * 7',
    '30 4 * jan-mar,dec *', '0 3 1,15 * mon', '0 3 13 * 5', '0 3 */2 * 1',
    '0 0 1-7 * 1-5', '0 0 29-31 * sun', '0 12 * * 1-5/2', '45 23 31 * *',
    '15 6 28 feb *',
);

foreach my $spec (@semantic) {
    my ( $rc, @lines ) = convert($spec);
    my $n = 40;
    my ( %got, $horizon );
    foreach my $expr (@lines) {
        my @t = systemd_fires( $expr, $n );
        $got{$_} = 1 foreach @t;
        # past the last time of a truncated line the union is incomplete
        $horizon = $t[-1] if @t == $n && ( !defined $horizon || $t[-1] lt $horizon );
    }
    my @want = cron_fires($spec);
    my @have = sort keys %got;
    if ( defined $horizon ) {
        @want = grep { $_ le $horizon } @want;
        @have = grep { $_ le $horizon } @have;
    }
    @want = @want[ 0 .. ( $#want < 150 ? $#want : 150 ) ];
    @have = @have[ 0 .. ( $#want < $#have ? $#want : $#have ) ] if @have;
    ok( scalar(@want) > 0, "reference fires for '$spec'" );
    is_deeply( \@have, \@want, "systemd fires like cron: '$spec'" );
}

done_testing();
