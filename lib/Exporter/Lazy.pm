use strict;
use warnings;

package Exporter::Lazy;

require Exporter;

sub _export_sub($&);

sub import
{
    my $importer = caller;
    no strict 'refs';
    *{"${importer}::import"} = \&_import;
}

sub _export_sub($&)
{
    my ($fq_name, $code) = @_;
    print "# Export $fq_name from ".(scalar caller(0)).' '.__PACKAGE__."\n";
    no strict 'refs';
    #my $sub = *{$fq_name};
    #if (defined $sub && $sub != $code) {
    #if (exists ${$pkg}{$name} && (exists ${$fq_name}{GLOB} || exists ${$fq_name}{CODE})) {
    #    require Carp;
    #    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    #    Carp::croak(__PACKAGE__." is incompatible with other $name".ref($sub));
    #}
    *$fq_name = $code;
}


my %all_imports;
my %exporters_for;

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
    *{"${importer}::AUTOLOAD"} = \&_AUTOLOAD;

    goto &Exporter::import;

    #my $no_check = 0;
    #if (@_ && $_[0] eq '-nocheck') {
    #    $no_check = 1;
    #    shift;
    #}

    no strict 'refs';
    #my $al_name = "${pkg}::AUTOLOAD";
    #my $al = *{$al_name};
    #if (defined $al && $al != \&_autoload) {
    #    require Carp;
    #    Carp::croak(__PACKAGE__." is incompatible with other AUTOLOAD");
    #}
    #*{$al_name} = \&_autoload;

    print "# import from $exporter into $importer\n";

    {
        (local $Carp::CarpLevel)++;
        _export_sub("${importer}::AUTOLOAD" => \&_AUTOLOAD);
    }

    # TODO handle ':all'
    #my %sym_map = map +($_, "${exporter}::$_"), @_;
    #@all_imports{ (map +("${importer}::$_"), keys %sym_map) } = (values %sym_map);
    #@all_imports{ (map +("${importer}::$_"), keys %sym_map) } = (values %sym_map);
    my %sym_map = map +("${importer}::$_", "${exporter}::$_"), @{"${exporter}::EXPORT_LAZY"};

    #unless ($no_check) {
        # TODO check conflicts
        # - with existing subs in the package
        #    - warn if the same symbol is imported twice
        #    - die if a different symbol is imported
        # - with previously imported symbols using __PACKAGE__
    #}

    #@all_imports{ (keys %sym_map) } = (values %sym_map);
    %all_imports = ( %all_imports, %sym_map );
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
