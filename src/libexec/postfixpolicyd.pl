#!/usr/bin/perl

# SPDX-FileCopyrightText: 2022 Synacor, Inc.
# SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only

use strict;
use lib '/opt/zextras/common/lib/perl5';
use Sys::Syslog qw(:DEFAULT setlogsock);
use Net::LDAP;
use Net::LDAP::Util qw(escape_filter_value);
use XML::Simple;

#
# Syslogging options for verbose mode and for fatal errors.
# NOTE: comment out the $syslog_socktype line if syslogging does not
# work on your system.
#
my $syslog_socktype = 'unix';
my $syslog_facility="mail";
my $syslog_options="pid";
our $syslog_priority="info";
our ($verbose, %attr, @ldap_url, $ldap_starttls_supported, $postfix_pw);
my ($option, $action, $ldap_url, @val);

$ENV{'HOME'}='/opt/zextras';
setlogsock $syslog_socktype;
openlog $0, $syslog_options, $syslog_facility;

my $localxml = XMLin("/opt/zextras/conf/localconfig.xml");

$ldap_starttls_supported = $localxml->{key}->{ldap_starttls_supported}->{value};
chomp ($ldap_starttls_supported);
$postfix_pw = $localxml->{key}->{ldap_postfix_password}->{value};
chomp($postfix_pw);
$ldap_url = $localxml->{key}->{ldap_url}->{value};
chomp($ldap_url);
@ldap_url = split / /, $ldap_url;

sub smtpd_access_policy {
  my($domain, $ldap, $mesg, $user, $daddr, $result, $entry);
  $daddr = lc $attr{recipient};
  ($user, $domain) = split /\@/, lc $attr{recipient};
  syslog $syslog_priority, "Recipient Domain: %s", $domain if $verbose;
  syslog $syslog_priority, "Recipient userid: %s", $user if $verbose;
  my $bound = 0;
  foreach my $url (@ldap_url) {
    $ldap = Net::LDAP->new($url) or next;
    if ( $ldap_starttls_supported && $url !~ /^ldaps/i ) {
      $mesg = $ldap->start_tls(verify => 'none');
      if ($mesg->code) {
        next;
      }
    }
    $mesg = $ldap->bind("uid=zmpostfix,cn=appaccts,cn=zimbra", password => $postfix_pw);
    if ($mesg->code) {
      next;
    } else {
      $bound = 1;
      last;
    }
  }
  if (!$bound) {
     syslog $syslog_priority, "Error: zmpostfixpolicyd unable to find working LDAP server";
     return "dunno";
  }
  my $edomain = escape_filter_value($domain);
  $result = $ldap->search(
            base => "",
            scope => 'sub',
            filter => "(&(zimbraDomainName=$edomain)(objectClass=zimbraDomain))",
            attrs => ['zimbraDomainType', 'zimbraMailCatchAllForwardingAddress'],
          );
  $entry = $result->entry(0);
  if ($entry) {
    if (lc($entry->get_value("zimbraDomainType") // "") eq "alias") {
      my $robject = $entry->get_value("zimbraMailCatchAllForwardingAddress") // "";
      syslog $syslog_priority, "Real Domain: %s", $robject if $verbose;
      my $euser = escape_filter_value($user);
      my $erobject = escape_filter_value($robject);
      my $edaddr = escape_filter_value($daddr);
      $result = $ldap->search(
                base => "",
                scope => 'sub',
                filter => "(&(|(zimbraMailDeliveryAddress=$euser"."$erobject)(zimbraMailDeliveryAddress=$edaddr)(zimbraMailAlias=$euser".
                "$erobject)(zimbraMailAlias=$edaddr)(zimbraMailCatchAllAddress=$euser"."$erobject)(zimbraMailCatchAllAddress=$erobject)".
                "(zimbraMailCatchAllAddress=$edaddr))(zimbraMailStatus=enabled))",
                attrs => ['1.1'],
              );
      $entry = $result->entry(0);
      $ldap->unbind;
      if ($entry) {
        return "dunno";
      } else {
        return "reject 5.1.1 Mailbox unavailable";
      }
    } else {
      $ldap->unbind;
      return "dunno";
    }
  }
  $ldap->unbind;
  return "dunno";
}

#
# Log an error and abort.
#
sub fatal_exit {
    my($first) = shift(@_);
    syslog "err", "fatal: $first", @_;
    exit 1;
}

#
# We don't need getopt() for now.
#
while ($option = shift(@ARGV)) {
    if ($option eq "-v") {
        $verbose = 1;
    } else {
        syslog $syslog_priority, "Invalid option: %s. Usage: %s [-v]",
                $option, $0;
        exit 1;
    }
}

#
# Unbuffer standard output.
#
select((select(STDOUT), $| = 1)[0]);

#
# Receive a bunch of attributes, evaluate the policy, send the result.
#
while (<STDIN>) {
    if (/([^=]+)=(.*)\n/) {
        $attr{substr($1, 0, 512)} = substr($2, 0, 512);
    } elsif ($_ eq "\n") {
        if ($verbose) {
            for (keys %attr) {
                syslog $syslog_priority, "Attribute: %s=%s", $_, $attr{$_};
            }
        }
        fatal_exit "unrecognized request type: '%s'", $attr{"request"}
            unless $attr{"request"} eq "smtpd_access_policy";
        $action = smtpd_access_policy();
        syslog $syslog_priority, "Action: %s", $action if $verbose;
        print STDOUT "action=$action\n\n";
        %attr = ();
    } else {
        chop;
        syslog $syslog_priority, "warning: ignoring garbage: %.100s", $_;
    }
}
