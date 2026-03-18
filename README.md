# Log::Fmt::XS

XS (C) implementation of `Log::Fmt`'s `_pairs_to_kvstr_aref` and `_quote_string` for faster logfmt event formatting.

## Description

Drop-in replacement for the pure Perl internals of [Log::Fmt](https://metacpan.org/pod/Log::Fmt). On `use`, it monkey-patches `Log::Fmt` to use the XS versions automatically.

Supports all `Log::Fmt` features: key sanitization, value quoting with proper Unicode escaping, nested array/hash expansion, coderef (lazy) evaluation, recursive structure detection, and String::Flogger integration.

## Usage

```perl
use Log::Fmt;
use Log::Fmt::XS;  # installs XS versions into Log::Fmt

my $line = Log::Fmt->format_event_string([
    key1 => $value1,
    key2 => $value2,
]);
```

## Building

```sh
perl Makefile.PL
make
make test
```

## Requirements

- Perl 5.20+
- Log::Fmt 3.013+
- String::Flogger

## License

Same terms as Perl 5.
