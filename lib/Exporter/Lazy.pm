use strict;
use warnings;

package Exporter::Lazy;

use warnings::register;

our $VERSION = '0.01';

BEGIN {
    require Exporter
}

my %exporters_for;
my %exporters;

sub import
{
    my ($importer, $file, $line) = caller($Exporter::ExportLevel);
    no strict 'refs';
    *{"${importer}::import"} = \&_import;

    $exporters{$importer} = [ $file, $line ];

    if (@_ && $_[0] eq '-nocheck') {
        #shift;
    }
    # The check is delayed to later because @EXPORT_LAZY
    # may be declared, but not yet initialized if we are
    # called either from a 'BEGIN' block or with 'use' and
    # @EXPORT_LAZY is declared outside or below the block.
}


sub _import
{
    my $importer = caller;
    my $exporter = $_[0];

    if (exists $exporters_for{$importer}) {
        push @{$exporters_for{$importer}}, $exporter;
    } else {
        $exporters_for{$importer} = [ $exporter ];
    }
    no strict 'refs';
    # TODO do not install AUTOLOAD if the importer
    #      imports all @EXPORT_LAZY (though @_)
    *{"${importer}::AUTOLOAD"} = \&_AUTOLOAD;

    # Forward argument parsing to Exporter
    # This allow to export both lazy and non-lazy
    # and to let the import choose to import lazy
    # symbols now (non lazy).
    goto &Exporter::import;
}

{
# The CHECK block may never run if the module is loaded at runtime instead of
# at BEGIN time. So we must do only optional checks here, and we want to
# avoid the warning as we are aware of the issue.
no warnings 'void';

CHECK {
    no strict 'refs';

    # Once all imports have been done, we check the exporters for mistakes
    # they may have done
    # Exporter which are loaded at runtime will not be checked. This is a
    # feature, not a bug.

    foreach my $e (keys %exporters) {
        # Check that we have an @EXPORT_LAZY
        # If not we could delete the AUTOLOAD in importers
        #print "Checking $e...\n";
        my @exports = @{"${e}::EXPORT_LAZY"};
        if (@exports) {
            # TODO check
            # - missing symbols in exporter
            # - conflicts with existing subs in importers
            #    - warn if the same symbol is imported twice
            #    - die if a different symbol is imported
	} else {
            #if (warnings::enabled("$e")) {
                warn("$e lacks \@EXPORT_LAZY at ".$exporters{$e}->[0]." line ".$exporters{$e}->[1]."\n");
            #}
        }
    }
}
}



sub _AUTOLOAD {
    no strict 'refs';
    my $fq_sub = our $AUTOLOAD;
    #print "import $fq_sub\n";
    my ($importer, $sub) = $fq_sub =~ m/^(.*)::([^:]*)$/;
    unless (exists $exporters_for{$importer}) {
        require Carp;
        Carp::croak("Undefined subroutine $fq_sub called (conflict with ". __PACKAGE__ .'?)');
    }
    my @exporters = @{ $exporters_for{$importer} };
    my $exporter;
    foreach my $e (@exporters) {
        if (grep { $_ eq $sub } @{"${e}::EXPORT_LAZY"}) {
            $exporter = $e;
            last;
        }
    }
    unless (defined $exporter) {
        require Carp;
        Carp::croak("Undefined subroutine $fq_sub (not exported by ".join(', ', @exporters).") called");
    }
    *$fq_sub = *{ "${exporter}::$sub" };
    goto &$fq_sub;
}


1;
__END__

=head1 NAME

Exporter::AutoLoad - Lazy exporter based on AUTOLOAD

=head1 SYNOPSIS

=head1 DESCRIPTION

EXports subs (only subs) in a lazy way: on usage. If an exported sub is not
used by the importing package, the symbol will not be created.

This module is useful if you want to limit the number of symbols used in your
program.

Drawbacks:

=over 4

=item *

The lazy import is implemented

=back

=cut

# vim: set ts=8 sw=4 sts=4:
