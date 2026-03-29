use v5.20.0;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Log::Fmt::XS',
    VERSION_FROM => 'lib/Log/Fmt/XS.pm',
    ABSTRACT     => 'XS implementation of Log::Fmt guts',
    AUTHOR       => 'Log::Fmt::XS contributors',
    LICENSE      => 'perl_5',
    MIN_PERL_VERSION => '5.020000',
    PREREQ_PM    => {
        'Log::Fmt'         => '3.014', # when it starts loading XS if it can
        'String::Flogger'  => 0,
    },
    TEST_REQUIRES => {
        'Test::More'  => '0.88',
        'Test::Deep'  => 0,
    },
    XSMULTI      => 0,
    TYPEMAPS     => [],
);
