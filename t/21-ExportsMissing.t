use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    $SIG{__WARN__} = sub {
        like $_[0], qr/^t::lib::ExportsMissing lacks \@EXPORT_LAZY/, 'warning raised when missing @EXPORT_LAZY';
    };
}

use t::lib::ExportsMissing;

