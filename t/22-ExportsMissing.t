use strict;
use warnings;
use Test::More tests => 1;

my $failed;
BEGIN {
    $SIG{__WARN__} = sub {
	$failed = 1;
	fail('Warning raised');
    };
}

require t::lib::ExportsMissing;
t::lib::ExportsMissing->import;

END {
    pass "No warning raised when module is loaded at runtime" unless $failed;
}
