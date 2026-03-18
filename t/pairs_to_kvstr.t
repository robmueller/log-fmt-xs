use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;

use Log::Fmt;
use Log::Fmt::XS;

# _pairs_to_kvstr_aref is now the XS version via import

sub kvstrs_ok {
  my ($pairs, $expected, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $got = Log::Fmt->_pairs_to_kvstr_aref($pairs);
  cmp_deeply($got, $expected, $desc) or diag explain $got;
}

subtest "simple key=value pairs" => sub {
  kvstrs_ok(
    [ foo => 'bar' ],
    [ 'foo=bar' ],
    "simple bare value",
  );

  kvstrs_ok(
    [ foo => 'bar', baz => 'quux' ],
    [ 'foo=bar', 'baz=quux' ],
    "multiple simple pairs",
  );

  kvstrs_ok(
    [ phl => 1, hou => 0 ],
    [ 'phl=1', 'hou=0' ],
    "numeric values",
  );
};

subtest "values needing quoting" => sub {
  kvstrs_ok(
    [ msg => 'hello world' ],
    [ 'msg="hello world"' ],
    "value with space gets quoted",
  );

  kvstrs_ok(
    [ eq => '0=1' ],
    [ 'eq="0=1"' ],
    "value with = gets quoted",
  );

  kvstrs_ok(
    [ q => 'say "hi"' ],
    [ 'q="say \\"hi\\""' ],
    "value with double quotes gets escaped",
  );

  kvstrs_ok(
    [ bs => 'foo\\bar' ],
    [ 'bs="foo\\\\bar"' ],
    "value with backslash gets escaped",
  );

  kvstrs_ok(
    [ tabby => "\tx = 1;" ],
    [ 'tabby="\\tx = 1;"' ],
    "tab becomes \\t",
  );

  kvstrs_ok(
    [ nl => "line1\nline2" ],
    [ 'nl="line1\\nline2"' ],
    "newline becomes \\n",
  );

  kvstrs_ok(
    [ cr => "a\rb" ],
    [ 'cr="a\\rb"' ],
    "carriage return becomes \\r",
  );
};

subtest "empty and invalid keys" => sub {
  kvstrs_ok(
    [ '' => 'val' ],
    [ '~=val' ],
    "empty key becomes ~",
  );

  kvstrs_ok(
    [ 'foo bar' => 'val' ],
    [ 'foo?bar=val' ],
    "space in key becomes ?",
  );

  kvstrs_ok(
    [ 'a=b' => 'val' ],
    [ 'a?b=val' ],
    "= in key becomes ?",
  );

  kvstrs_ok(
    [ 'a"b' => 'val' ],
    [ 'a?b=val' ],
    "double quote in key becomes ?",
  );

  kvstrs_ok(
    [ "a\\b" => 'val' ],
    [ 'a?b=val' ],
    "backslash in key becomes ?",
  );
};

subtest "undef values" => sub {
  kvstrs_ok(
    [ key => undef ],
    [ 'key=~missing~' ],
    "undef value becomes ~missing~",
  );
};

subtest "nested arrayrefs" => sub {
  kvstrs_ok(
    [ games => [ 'done', 'in-progress' ] ],
    [ 'games.0=done', 'games.1=in-progress' ],
    "arrayref values get flattened with numeric indices",
  );

  kvstrs_ok(
    [ arr => [ 'a', 'b', 'c' ] ],
    [ 'arr.0=a', 'arr.1=b', 'arr.2=c' ],
    "three-element array",
  );
};

subtest "nested hashrefs" => sub {
  kvstrs_ok(
    [ data => { alpha => 1, beta => 2 } ],
    [ 'data.alpha=1', 'data.beta=2' ],
    "hashref values get flattened with sorted keys",
  );
};

subtest "deeply nested structures" => sub {
  kvstrs_ok(
    [
      array => [
        { name => [ 'Ricardo', 'Signes' ], limbs => { arms => 2, legs => 2 } },
        [ 2, 4, 6 ],
      ],
    ],
    [
      'array.0.limbs.arms=2',
      'array.0.limbs.legs=2',
      'array.0.name.0=Ricardo',
      'array.0.name.1=Signes',
      'array.1.0=2',
      'array.1.1=4',
      'array.1.2=6',
    ],
    "deeply nested array/hash structure",
  );
};

subtest "recursive structures" => sub {
  my $struct = {};
  $struct->{recurse} = $struct;

  kvstrs_ok(
    [ recursive => $struct ],
    [ 'recursive.recurse=&recursive' ],
    "recursive hashref produces backreference",
  );
};

subtest "coderef (lazy) values" => sub {
  my $called = 0;
  my $cb = sub { $called++; return 'lazy_val' };

  kvstrs_ok(
    [ key => $cb ],
    [ 'key=lazy_val' ],
    "coderef is called to produce value",
  );

  is($called, 1, "coderef called exactly once");
};

subtest "ref-to-ref (String::Flogger)" => sub {
  kvstrs_ok(
    [ bar => \{ a => 1 } ],
    [ re(qr/^bar=/) ],
    "refref produces flogged output",
  );
};

subtest "UTF-8 values" => sub {
  # ë (U+00EB) is a safe non-ASCII character — should appear as UTF-8 bytes
  # in the output without \x{} escaping
  kvstrs_ok(
    [ name => "Jürgen" ],
    [ "name=\"J\xc3\xbcrgen\"" ],
    "safe non-ASCII chars (ü) are UTF-8 encoded directly",
  );
};

subtest "control characters and special escapes" => sub {
  # ZWJ (U+200D) is a Cf character — gets \x{} escaped
  kvstrs_ok(
    [ string => "NL \x0a CR \x0d \"Q\" ZWJ \x{200D} \\nothing \x{00EB}" ],
    [ 'string="NL \\n CR \\r \\"Q\\" ZWJ \\x{e2}\\x{80}\\x{8d} \\\\nothing ' . "\xc3\xab" . '"' ],
    "control chars, ZWJ, quotes, backslash, and ë all handled correctly",
  );
};

subtest "vertical whitespace" => sub {
  # LINE SEPARATOR (U+2028) should be escaped to its UTF-8 bytes
  kvstrs_ok(
    [ string => "line \x{2028} spacer" ],
    [ "string=\"line \\x{e2}\\x{80}\\x{a8} spacer\"" ],
    "LINE SEPARATOR is escaped via UTF-8 byte \x{} sequences",
  );
};

subtest "empty value" => sub {
  kvstrs_ok(
    [ key => '' ],
    [ 'key=""' ],
    "empty string gets quoted",
  );
};

subtest "bogus subkey characters" => sub {
  kvstrs_ok(
    [ valid => { 'foo bar' => 'revolting' } ],
    [ 'valid.foo?bar=revolting' ],
    "bogus key chars in recursion become ?",
  );
};

subtest "prefix handling" => sub {
  # Test with explicit prefix argument
  my $got = Log::Fmt->_pairs_to_kvstr_aref(
    [ alpha => 1, beta => 2 ],
    {},
    'pfx',
  );
  cmp_deeply(
    $got,
    [ 'pfx.alpha=1', 'pfx.beta=2' ],
    "explicit prefix prepended to keys",
  );
};

subtest "match full format_event_string output" => sub {
  # Verify XS output matches what format_event_string produces
  my @test_cases = (
    {
      input => [ phl => 1, hou => 0, games => [ 'done', 'in-progress' ] ],
      expected => 'phl=1 hou=0 games.0=done games.1=in-progress',
      desc => 'basic data with arrayref',
    },
    {
      input => [ tabby => "\tx = 1;" ],
      expected => 'tabby="\\tx = 1;"',
      desc => 'tab escape',
    },
    {
      input => [ equals => "0=1" ],
      expected => 'equals="0=1"',
      desc => 'equals sign quoted',
    },
    {
      input => [ revsol => "foo\\bar" ],
      expected => 'revsol="foo\\\\bar"',
      desc => 'backslash quoted',
    },
  );

  for my $tc (@test_cases) {
    my $got = Log::Fmt->format_event_string($tc->{input});
    is($got, $tc->{expected}, "format_event_string: $tc->{desc}");
  }
};

done_testing;
