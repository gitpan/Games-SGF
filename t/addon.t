use Test::More tests => 15;                      # last test to print
use Games::SGF;
require 't/sgf_test.pm';
my $sgf_in = <<SGF;
(;KM[5.00];W[df];B[aa];AW[ab][ac];CR[aa][ac:cd])
SGF

# create Parsers
my $parser = new Games::SGF();

ok( $parser, "Create Parser Object" );

# add tags to parsers
sgf_ok( $parser->addTag('KM', $parser->T_GAME_INFO, $parser->V_REAL ), "addTag");
# add point, stone, move callbacks
sgf_ok( $parser->setStoneRead(\&parsepoint), "Add Stone Parse");
sgf_ok( $parser->setMoveRead(\&parsepoint), "Add Move Parse");
sgf_ok( $parser->setPointRead(\&parsepoint), "Add Point Parse");

# read in $sgf_in
sgf_ok( $parser->readText($sgf_in));

test_nav( $parser, "parse");

sub parsepoint {
   my $value = shift;
   my( $x, $y) = split //, $value;
   return [ ord($x) - ord('a'), ord($y) - ord('a') ];
}
 


sub test_nav {
   my $sgf = shift;
   my $name = shift;

   tag_eq( $sgf, $name,
      KM => 5 );
   sgf_func($sgf, "next", $name);
   tag_eq( $sgf, $name, W => [[3,5]] );

   sgf_func($sgf, "next", $name);
   tag_eq( $sgf, $name, B => [[0,0]] );

   sgf_func($sgf, "next", $name);
   tag_eq( $sgf, $name, AW => [[0,1],[0,2]] );

   sgf_func($sgf, "next", $name);
   tag_eq( $sgf, $name, CR => [[0,0],$sgf->compose([0,2],[2,3])] );
}
