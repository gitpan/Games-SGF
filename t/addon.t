use Test::More tests => 15;                      # last test to print
use Games::SGF;
require 't/sgf_test.pl';
my $sgf_in = <<SGF;
(;KM[5.00];W[df];B[aa];AW[ab][ac];CR[aa][ac:cd])
SGF

# create Parsers
my $parser = new Games::SGF();

ok( $parser, "Create Parser Object" );
diag( $parser->err ) if $parser->err;

# add tags to parsers
ok($parser->addTag('KM', $parser->T_GAME_INFO, $parser->V_REAL ), "addTag");
diag( $parser->err ) if $parser->err;

# add point, stone, move callbacks
ok( $parser->setStoneRead(\&parsepoint), "Add Stone Parse");
diag( $parser->err ) if $parser->err;

ok( $parser->setMoveRead(\&parsepoint), "Add Move Parse");
diag( $parser->err ) if $parser->err;

ok( $parser->setPointRead(\&parsepoint), "Add Point Parse");
diag( $parser->err ) if $parser->err;


# read in $sgf_in
ok( $parser->readText($sgf_in), "Read SGF");
diag( $parser->err ) if $parser->err;
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
      KM => [5] );
   ok($sgf->next, "next $name");
   diag($sgf->err) if $sgf->err;
   tag_eq( $sgf, $name, W => [[3,5]] );

   ok($sgf->next, "next1 $name");
   diag($sgf->err) if $sgf->err;
   tag_eq( $sgf, $name, B => [[0,0]] );

   ok($sgf->next, "next2 $name");
   diag($sgf->err) if $sgf->err;
   tag_eq( $sgf, $name, AW => [[0,1],[0,2]] );

   ok($sgf->next, "next3 $name");
   diag($sgf->err) if $sgf->err;
   tag_eq( $sgf, $name, CR => [[0,0],$sgf->compose([0,2],[2,3])] );
}
