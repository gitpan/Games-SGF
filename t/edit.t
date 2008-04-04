use Test::More tests => 33;                      # last test to print
use Games::SGF;
use Data::Dumper;
require 't/sgf_test.pl';
my $sgf_in = <<SGF;
(;KM[5.00];W[df];B[aa];AW[ab][ac];CR[aa][ac:cd])
SGF

# create Parsers
my $parser = new Games::SGF(debug => 1);

ok( $parser, "Create Parser Object" );
diag( $parser->err ) if $parser->err;

# add tags to parsers
ok($parser->addTag('KM', $parser->T_GAME_INFO, $parser->V_REAL ), "addTag");
diag( $parser->err ) if $parser->err;

# read in $sgf_in
ok( $parser->readText($sgf_in), "Read SGF");
diag( $parser->err ) if $parser->err;
test_nav( $parser, "parse");

1 while $parser->gotoParent;
1 while $parser->prev;
ok($parser->next, "moving up a node");
   diag($parser->err) if $parser->err;
ok($parser->next, "moving up a node");
   diag($parser->err) if $parser->err;
ok($parser->next, "moving up a node");
   diag($parser->err) if $parser->err;
ok($parser->splitBranch, "splitting");
   diag($parser->err) if $parser->err;
ok($parser->addVariation, "adding variation");
   diag($parser->err) if $parser->err;
ok($parser->property("W", $parser->move("ab")), "adding prop");
   diag($parser->err) if $parser->err;


1 while $parser->gotoParent;
1 while $parser->prev;
test_nav($parser, "pass-2", 1);


sub test_nav {
   my $sgf = shift;
   my $name = shift;
   my $passTwo = shift;

   tag_eq( $sgf, $name,
      KM => [5] );
   ok($sgf->next, "next $name");
   diag($sgf->err) if $sgf->err;
   tag_eq( $sgf, $name, W => $sgf->move("df") );

   ok($sgf->next, "next1 $name");
   diag($sgf->err) if $sgf->err;
   tag_eq( $sgf, $name, B => $sgf->move("aa") );

   if($passTwo) {
      ok($sgf->gotoVariation(1), "goto new var");
      tag_eq( $sgf, "new-$name", W => $sgf->move("ab") );
      ok($sgf->removeNode, "remove node");
      ok($sgf->gotoParent(), "going back to mainline");
      ok($sgf->removeVariation(1), "removing added variation");
      ok($sgf->flatten, "flatten out variation");
   }
      ok($sgf->next, "next2 $name");
      diag($sgf->err) if $sgf->err;
print Dumper $parser;
   tag_eq( $sgf, $name, AW => [$sgf->stone("ab"),$sgf->stone("ac")] );

   ok($sgf->next, "next3 $name");
   diag($sgf->err) if $sgf->err;
   tag_eq( $sgf, $name, CR => [
                  $sgf->point("aa"),
                  $sgf->compose($sgf->point("ac"),
                        $sgf->point("cd"))] );
}
