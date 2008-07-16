use Test::More tests => 21;                      # last test to print
use Games::SGF;
require 't/sgf_test.pl';
my $sgf_in = <<SGF;
(;KM[5.00];W[df];B[aa];AW[ab][ac];CR[aa][ac:cd])
SGF
#TODO make a test check and write callback
# create Parsers
my $parser = new Games::SGF(Fatal => 0, Warn => 0, Debug => 0);

ok( $parser, "Create Parser Object" );
diag( $parser->Fatal ) if $parser->Fatal;

# add tags to parsers
ok($parser->addTag('KM', $parser->T_GAME_INFO, $parser->V_REAL ), "addTag");
diag( $parser->Fatal ) if $parser->Fatal;

# try adding non CODE callbacks
ok( not( $parser->setStoneRead("something")), "Add Bad Stone Parse");
ok( not( $parser->setMoveRead("Something")), "Add Bad Move Parse");
ok( not( $parser->setPointRead("Something")), "Add Bad Point Parse");

# add point, stone, move callbacks
ok( $parser->setStoneRead(\&parsepoint), "Add Stone Parse");
diag( $parser->Fatal ) if $parser->Fatal;

ok( $parser->setMoveRead(\&parsepoint), "Add Move Parse");
diag( $parser->Fatal ) if $parser->Fatal;

ok( $parser->setPointRead(\&parsepoint), "Add Point Parse");
diag( $parser->Fatal ) if $parser->Fatal;

# redefining subroutines
ok( not($parser->setStoneRead(\&parsepoint)), "Readding Stone Parse");
ok( not($parser->setMoveRead(\&parsepoint)), "Readding Move Parse");
ok( not($parser->setPointRead(\&parsepoint)), "Readding Point Parse");

# read in $sgf_in
ok( $parser->readText($sgf_in), "Read SGF");
diag( $parser->Fatal ) if $parser->Fatal;
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
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, W => [[3,5]] );

   ok($sgf->next, "next1 $name");
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, B => [[0,0]] );

   ok($sgf->next, "next2 $name");
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, AW => [[0,1],[0,2]] );

   ok($sgf->next, "next3 $name");
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, CR => [[0,0],$sgf->compose([0,2],[2,3])] );
}
