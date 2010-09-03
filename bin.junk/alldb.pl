#! /usr/bin/perl

use strict;
use warnings;

use DBI;


sub main {
    my @dbinst = qw( otterlive:3301 otterpipe1:3302 otterpipe2:3303 );
    my ($user, $pass) = qw( ottro );

    foreach my $dbinst (@dbinst) {
	my ($host, $port) =
	  $dbinst =~ m{^([-a-z0-9.]+):(\d+)$}i or
	    die "Can't parse dbinst '$dbinst'";
	my $dbh = DBI->connect("DBI:mysql:host=$host;port=$port", $user, $pass, { RaiseError => 1 });
	run_for_inst($dbh, $dbinst);
    }
}

sub run_for_inst {
    my ($dbh, $what) = @_;

#    warn "$what\n";
    foreach my $db (@{ $dbh->selectcol_arrayref("show databases") }) {
	$dbh->do("use `$db`");
	run_for_db($dbh, "$what > $db");
    }
}

sub run_for_db {
    my ($dbh, $what) = @_;

#    warn " $what\n";
    foreach my $tbl (@{ $dbh->selectcol_arrayref("show tables") }) {
	my (undef, $tdef) = qw(1 2);#$dbh->selectrow_array("show create table `$tbl`");
	run_for_table($dbh, "$what.$tbl", $tbl, $tdef);
    }
}

sub run_for_table {
    my ($dbh, $what, $tbl, $tdef) = @_;

    my $type = join "/", ($tdef =~ m{\bENGINE=(\w+)\b});
    $type ||= "???";

#    print "  $what:\t$type\n";

#    if ($type eq 'MyISAM') {
#	my ($rows) = $dbh->selectrow_array("select count(*) from `$tbl`");
#	print "  $what:\t$type\t$rows\n";
#    }
}

main();
