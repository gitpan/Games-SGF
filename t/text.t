use Test::More tests => 3;
use Games::SGF;
use Data::Dumper;
require "t/sgf_test.pl";

my $sgf_in = <<SGF;
(;AP[Some
App:Vers
ion 1]C[SomeText
THan may be on multiple lines])
SGF

my $sgf = new Games::SGF();

ok( $sgf->readText($sgf_in), "Read File");
tag_eq( $sgf, "Root Node",
   AP => [$sgf->compose("Some App","Vers ion 1")],
   C => "SomeText
THan may be on multiple lines"
);
#print Dumper $sgf;
