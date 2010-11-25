#! /usr/bin/perl

use strict;
use warnings;

use DBI;


sub main {
    my ($user, $pass) = qw( ottro );
    my @dbinst;
#    push @dbinst, qw( vegabuild:3304 vegabuild:5304 );
    push @dbinst, qw( otterlive:3301 otterpipe1:3302 otterpipe2:3303 );
    my $code = \&show_table_type;

    my @all_tables = enumerate_all($user, $pass, @dbinst);

    # At this point we have no open connections - we could dice
    # @all_tables up and allocate to forked processes.

#    run_serial($code, $user, $pass, @all_tables);
#    run_parallel($code, $user, $pass, @all_tables);
    run_parallel($code, $user, $pass, deal_alltables(4, @all_tables));
}

sub run_serial {
    my ($code, $user, $pass, @all_tables) = @_;
    foreach my $info (@all_tables) {
	run_for_tables($code, $user, $pass, @$info);
    }
}

sub run_parallel {
    my ($code, $user, $pass, @all_tables) = @_;

    # XXX: too much state kicking around in block-scoped vars
    my @kid; # pids launched, for parent
    my $pid = -1; # guaranteed false when we're a child
    my $dbinst; # set for kids, junk in parent

    $SIG{INT} = sub {
	if ($pid) {
	    warn "Caught SIGINT, killing kids...\n";
	    kill 2, @kid;
	} else {
	    die "Child ($dbinst) caught SIGINT\n";
	}
    };

    $| = 1;
    foreach my $info (@all_tables) {
	$pid = fork();
	$dbinst = $$info[0];
	if (!defined $pid) {
	    warn "w: fork failed: $!";
	    $pid = -2; # assert parenthood again; also failure flag
	    last; # don't try to make any more
	} elsif ($pid) {
	    # parent just does launching
	    push @kid, $pid;
	} else {
	    # child
	    $| = 1;
	    run_for_tables($code, $user, $pass, @$info);
	    last;
	}
    }
    # parent & all children continue here...

    if ($pid) {
	# parent again
	my @done;
	while (@kid > @done) {
	    my $done = wait;
	    push @done, [ $done, $? ];
	}
	# XXX: we risk killing random other process re-using @kid pids, since we don't (may not be able to) remove entries when done
	if ($pid == -2) {
	    die "Failed to run for all subprocesses\n";
	}
    } else {
	# child finished
    }
}

main();


# Returns the list @all_tables
#
# Uses and throws away a $dbh per @dbinst.  This operation is pretty
# quick.
sub enumerate_all {
    my ($user, $pass, @dbinst) = @_;
    my @all_tables; # list of [ $dbinst, $dsn, \@db_tables ]

    foreach my $dbinst (@dbinst) {
	my ($host, $port) =
	  $dbinst =~ m{^([-a-z0-9.]+):(\d+)$}i or
	    die "Can't parse dbinst '$dbinst'";
	my $dsn = "DBI:mysql:host=$host;port=$port";
	my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 1 });

	my @db_tables; # list of [ $database_name, $table_name ] pairs
	foreach my $db (@{ $dbh->selectcol_arrayref("show databases") }) {
	    eval {
		my $qdb = $dbh->quote_identifier($db);
		push @db_tables,
		  map {[ $db, $_ ]}
		    @{ $dbh->selectcol_arrayref("show tables from $qdb") };
	    };
	    warn "Skipping tables in $dbinst > $db: $@" if $@;
	}

	push @all_tables, [ $dbinst, $dsn, \@db_tables ];
    }

    return @all_tables;
}


# For each database instance, deal out the table list into $deal_ways
# pieces.  With run_parallel this will cause (up to) $deal_ways client
# processes per database instance.
sub deal_alltables {
    my ($deal_ways, @alltables_in) = @_;
    my @alltables_out;

    foreach my $info (@alltables_in) {
	my ($dbinst, $dsn, $db_tables) = @$info;

	# Deal out the tables
	my @dealt;
	for (my $i=0; $i < @$db_tables; $i++) {
	    push @{ $dealt[$i % $deal_ways] }, @$db_tables[$i];
	}

	# Make new groups
	foreach my $db_tables (@dealt) {
	    push @alltables_out, [ $dbinst, $dsn, $db_tables ] if @$db_tables;
	}
    }

    return @alltables_out;
}


# Connect to $dsn and run $code for each listed table.
sub run_for_tables {
    my ($code, $user, $pass,   $dbinst, $dsn, $db_tables) = @_;
    # XXX: passing too much stuff in here
    my $dbh = DBI->connect($dsn, $user, $pass, { RaiseError => 1 });

    eval {
	foreach my $dbtbl (@$db_tables) {
	    my ($db, $table) = @$dbtbl;
	    $dbh->do("use ".$dbh->quote_identifier($db));
	    $code->($dbh, "$dbinst > $db.$table", $table);
	}
    };
    warn "Run for $dbinst abended: $@" if $@;
}


sub show_table_type {
    my ($dbh, $db_what, $tbl) = @_;

    my (undef, $tdef) = $dbh->selectrow_array("show create table `$tbl`");
    my $type = join "/", ($tdef =~ m{\bENGINE=(\w+)\b});
    $type ||= "???";

    print "  $db_what:\t$type\n";

#    if ($type eq 'MyISAM') {
#	my ($rows) = $dbh->selectrow_array("select count(*) from `$tbl`");
#	print "  $db_what:\t$type\t$rows\n";
#    }
}

sub show_table_size {
    my ($dbh, $db_what, $tbl) = @_;

    my @info = $dbh->selectrow_array("show table status like ?", {}, $tbl);
    printf("  %s:\t%.3f MiB\n", $db_what, $info[6] / 1024 / 1024);
}
