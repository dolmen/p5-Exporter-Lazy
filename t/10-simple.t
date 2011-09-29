use strict;
use warnings;

use Test::More tests => 9;

{
    package Ga;
    our @EXPORT_LAZY = qw<BU MEU>;
    use Exporter::Lazy;

    sub BU() { "BU!" }
    sub MEU() { 3 }
    sub ZO { 5*shift }
    1;
}

#use Ga;
BEGIN { Ga->import; }

is Ga::BU, 'BU!';

isnt \&main::BU, \&Ga::BU, 'main::BU is not defined';
is BU(), 'BU!';
is   \&main::BU, \&Ga::BU, 'main::BU is now defined';

is &BU, 'BU!';

is &MEU, 3;
is MEU(), 3;

{
    local $@;
    eval { ZO(3) };
    ok $@, 'ZO not exported';
    like $@, qr/^Undefined subroutine/, 'Exception raised';
    #diag $@;
}


