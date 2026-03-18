use v5.20;
use warnings;
package Log::Fmt::XS 0.001;

use XSLoader;
XSLoader::load('Log::Fmt::XS', $Log::Fmt::XS::VERSION);

sub import {
    require Log::Fmt;
    no warnings 'redefine';
    *Log::Fmt::_pairs_to_kvstr_aref = \&_pairs_to_kvstr_aref;
    *Log::Fmt::_quote_string = \&_quote_string;
}

1;
