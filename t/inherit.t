use Test::More tests => 33;
use Games::SGF;
require "t/sgf_test.pl";

my $sgf_in = <<SGF;
(;C[Some Prop]PM[2];B[ab]
   (;W[fg])
   (;W[ad]PM[1];B[de])
)
SGF

my $sgf = new Games::SGF();

ok( $sgf->readText($sgf_in), "Read SGF_IN");
testNav($sgf);
my $sgf_out;
ok( $sgf_out = $sgf->writeText, "Writing Text");
$sgf = new Games::SGF();
ok( $sgf->readText($sgf_out), "Read SGF_OUT");
testNav($sgf);


sub testNav {
   my $sgf = shift;
   tag_eq( $sgf, "Root Node",
      C => "Some Prop",
      PM => 2
   );
   $sgf->err("");
   ok($sgf->next, "goto second node");
   tag_eq( $sgf, "Second Node",
      B => $sgf->move('ab'),
      PM => 2
   );
   $sgf->err("");
   ok($sgf->gotoVariation(0), "First Branch");
   tag_eq( $sgf, "First Branch First Node",
      W => $sgf->move('fg'),
      PM => 2
   );
   $sgf->err("");
   ok($sgf->gotoParent, "Going to Parent");
   ok($sgf->gotoVariation(1), "Second Branch");
   tag_eq( $sgf, "Second Branch First Node",
      W => $sgf->move('ad'),
      PM => 1
   );
   ok($sgf->next, "goto second branch second node");
   tag_eq( $sgf, "Second Branch Second Node",
      B => $sgf->move('de'),
      PM => 1
   );
}
