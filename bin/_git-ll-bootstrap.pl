#! /usr/bin/env perl

use strict;
use warnings;
use Cwd 'abs_path';

=head1 NAME

_git-ll-bootstrap.pl - internal utility to obtain Perl local::lib

=head1 DESCRIPTION

This utility is used by C<git ll-init> when L<local::lib> is not
already available.

=head1 CAVEATS

It uses L<CPAN::Shell> to do the work of finding, fetching and
unpacking the files.

You may need to configure CPAN access before using this.

It is also possible that this script is over-friendly with some
CPAN::* internals, so may not work with all versions.  It was written
using v1.960001 .

=cut


sub main {
    my ($instdir) = @_;
    $instdir = abs_path($instdir);

    die "Syntax: $0 <instdir>\n\nBootstrap Perl local::lib into instdir\n"
      unless -d $instdir;

    print "\n$0: Going to bootstrap local::lib via CPAN::Shell into $instdir\n";


    # Use CPAN _only_ to get the tarball
    #
    # Module::AutoInstall can pass the dependency buck back to CPAN,
    # letting the install go bad due to lack of --bootstrap ?
    my $dir = do {
        my %old_ENV = %ENV;
        local %ENV = %ENV;

        # %ENV and $PWD may change, but we're ready for that
        cpan_grab();

        # die hashdiff(\%old_ENV, \%ENV);
    };

    chdir $dir;
    run(perl => 'Makefile.PL', "--bootstrap=$instdir");
    run(qw( make test ));
    run(qw( make install ));

    return 0;
}


sub cpan_grab {
    require CPAN;

    my @mod = CPAN::Shell->expand(Module => 'local::lib');
    die "$0 fail: Expected one module, found (@mod)\n"
      unless 1 == @mod && eval { $mod[0]->can('inst_version') };

    my $build = $mod[0]->get;
    # get: unpacked the tarball
    die "$0 fail: Expected an unpacked CPAN::Distribution, found ($build)\n"
      unless $build && eval { $build->can('dir') };

    my $dir = $build->dir;
    die "$0 fail: Expected Makefile.PL in $dir"
      unless -f "$dir/Makefile.PL";

    return $dir;
}


sub run {
    my @cmd = @_;
    print "  @cmd\n";
    system(@cmd);
    my $err;
    if ($? == -1) {
        $err = "$!";
    } elsif ($? & 127) {
        $err = sprintf('signal %d%s', ($? & 127),  ($? & 128) ? ' (core dumped)' : '');
    } elsif ($?) {
        $err = sprintf('exited %d', $? >> 8);
    } # else OK
    die "Failed: @cmd: $err\n" if defined $err;
    return ();
}


sub hashdiff { # for debug
    my ($a, $b) = @_;

    my %a = %$a;
    my %b = %$b;

    while (my ($k, $v) = each %a) {
        next unless defined $b{$k} && $v eq $b{$k};
        delete $a{$k};
        delete $b{$k};
    }

    while (my ($k, $v) = each %b) {
        next unless defined $a{$k} && $v eq $a{$k};
        delete $a{$k};
        delete $b{$k};
    }

    require YAML::XS;
    YAML::XS->import('Dump');
    return Dump({ hashdiff => { a => \%a, b => \%b }});
}

exit main(@ARGV);
