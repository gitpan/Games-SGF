use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new(
   module_name => 'Games::SGF',
   license  => 'perl',
   requires => {
      'perl'         => '5.6.1',
      'enum'         => '1.016',
   },
   build_requires => {
      'Test::More'   => 0.70,
      'Data::Dumper' => 2.121,
      'Scalar::Util' => 1.14,
   },
);
$build->create_build_script;
