use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Games::SGF',
    AUTHOR              => 'David Whitcomb <whitcode@gmail.com>',
    VERSION_FROM        => 'lib/Games/SGF.pm',
    ABSTRACT_FROM       => 'lib/Games/SGF.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'enum'       => 1.016
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Games-SGF-*' },
);
