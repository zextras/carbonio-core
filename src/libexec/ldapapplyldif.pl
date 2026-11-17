#!/usr/bin/perl

# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only

use strict;
use lib "/opt/zextras/common/lib/perl5";
use Zextras::Util::Common;
use File::Grep qw (fgrep);
use File::Path;
use File::Temp;
use Net::LDAP;
use Net::LDAP::LDIF;
use Net::LDAP::Entry;
use Crypt::SaltedHash;
use MIME::Base64;

my $source_config_dir = "/opt/zextras/common/etc/openldap";
my $config_dir = "/opt/zextras/conf";
my $ldap_config_dir="/opt/zextras/data/ldap/config/cn\=config";

my $zimbra_user=getLocalConfig("zimbra_user");
my $zimbra_ldap_userdn = getLocalConfig("zimbra_ldap_userdn");
my $zimbra_ldap_password = getLocalConfig("zimbra_ldap_password");
my $ldap_root_password = getLocalConfig("ldap_root_password");
my $ldap_master_url = getLocalConfig("ldap_master_url");
my $ldap_is_master = getLocalConfig("ldap_is_master");
my $ldap_starttls_supported = getLocalConfig("ldap_starttls_supported");
my $zimbra_tmp_directory = getLocalConfig("zimbra_tmp_directory");

if (!-d $zimbra_tmp_directory) {
  File::Path::mkpath("$zimbra_tmp_directory");
}

# Get the SHA password.
my $ctx = Crypt::SaltedHash->new(algorithm => 'SHA-512', salt_len => '8');
$ctx->add("$ldap_root_password");
my $root_ssha_password = $ctx->generate;

$ctx = Crypt::SaltedHash->new(algorithm => 'SHA-512', salt_len => '8');
$ctx->add("$zimbra_ldap_password");
my $zimbra_ssha_password = $ctx->generate;

# Update cn=config
my $infile="$ldap_config_dir/olcDatabase\=\{0\}config.ldif";
my $mime_root_passwd=MIME::Base64::encode($root_ssha_password,"");
chomp ($mime_root_passwd);

# Build the new file next to the destination, not in the world-writable tmp
# directory, and rename it into place.
my ($tmpfh, $outfile) = File::Temp::tempfile("olcDatabase={0}config.ldif.XXXXXX", DIR => $ldap_config_dir);
open(IN,"<$infile");
while (<IN>) {
  if ($_ =~ /^olcRootPW/) {
    $_ =~ s|^olcRootPW.*|olcRootPW:: $mime_root_passwd|;
  }
  print $tmpfh $_;
}
close IN;
my ($uid, $gid) = (getpwnam($zimbra_user))[2,3];
chown($uid, $gid, $tmpfh) if defined $uid;
chmod(0600, $tmpfh);
close $tmpfh;
if ( -s $outfile ) {
  if (!rename($outfile, $infile)) {
    print "Warning: failed to write $infile\n";
    unlink($outfile);
  }
} else {
  unlink($outfile);
  print "Warning: Failed to update root password.\n";
}

# Update carbonio.ldif
unlink("${config_dir}/carbonio.ldif");

$infile = "$source_config_dir/zimbra/carbonio.ldif";
$outfile = "$config_dir/carbonio.ldif";
my $ldifin = Net::LDAP::LDIF->new( "$infile", "r", onerror => 'undef' );
my $ldifout = Net::LDAP::LDIF->new("$outfile", "w", onerror => 'undef' );
while( not $ldifin->eof()) {
  my $entry = $ldifin->read_entry ( );
  if ( $ldifin->error ( ) ) {
    print "Error msg: ", $ldifin->error ( ), "\n";
    print "Error lines:\n", $ldifin->error_lines ( ), "\n";
  } elsif ( $entry ) {
      if ($entry->dn() eq "uid=zimbra,cn=admins,cn=zimbra") {
        $entry->replace (
          userPassword => "${zimbra_ssha_password}",
        );
      }
    $ldifout->write($entry);
  }
}
$ldifin->done ( );
$ldifout->done ( );

exit 0;

sub getLocalConfig {
  my $key = shift;

  return $main::loaded{lc}{$key}
    if (exists $main::loaded{lc}{$key});

  my $val = qx(/opt/zextras/bin/zmlocalconfig -x -s -m nokey ${key} 2> /dev/null);
  chomp $val;
  $main::loaded{lc}{$key} = $val;
  return $val;
}

