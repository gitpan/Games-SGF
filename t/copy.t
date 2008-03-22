use Test::More tests => 71;                      # last test to print
use Games::SGF;
require 't/sgf_test.pl';

my $sgf_in = <<SGF;
(;GM[1]FF[4]AP[qGo:1.5.4]ST[1]
SZ[19]HA[0]KM[5.5]PW[White]PB[Black]
AB[dp][ep][eq]AW[do][eo][fp][fq]
;B[go]
(
;W[hp];B[io]
)
(
;W[hq];B[hp];W[ip]LB[fo:A]C[Some Comment \\] with a needed escape]
;B[iq];W[hr]
)
)
SGF

# create Parsers
my $parser1 = new Games::SGF();
my $parser2 = new Games::SGF();

sgf_ok( $parser1, "Create Parser Object 1" );
sgf_ok( $parser2, "Create Parser Object 2" );

# add tags to parsers
sgf_ok( $parser1, $parser1->addTag('KM', $parser1->T_GAME_INFO, $parser1->V_REAL ), "addTag");
sgf_ok( $parser1, $parser2->addTag('KM', $parser2->T_GAME_INFO, $parser2->V_REAL ), "addTag");

# read in $sgf_in
sgf_ok( $parser1, $parser1->readText($sgf_in), "Read Initial SGF Text");
# write it back out
my $sgf_out2 = $parser1->writeText;
sgf_ok( $parser1, $sgf_out2, "Write the parsed Tree");

# read it in the second parser
sgf_ok( $parser2, $parser2->readText($sgf_out2), "Read Second SGF Text");
test_nav( $parser1, "parse1");
test_nav( $parser2, "parse2");
sub test_nav {
   my $sgf = shift;
   my $name = shift;

   tag_eq( $sgf, $name,
      GM => 1,
      FF => 4,
      AP => [$sgf->compose("qGo","1.5.4")],
      ST => 1,
      SZ => 19,
      HA => 0,
      KM => 5.5,
      PW => "White",
      PB => "Black",
      AB => ["dp","ep","eq"],
      AW => ["do","eo","fp","fq"] );
   #node_next($sgf, "1-$name");

   sgf_func($sgf, "next", "1-$name");
   tag_eq( $sgf, $name, B => "go" );

   my ($num_var) = sgf_func($sgf, "variations", "1-variation");
   ok($num_var == 2, "number of variations");
   sgf_func($sgf, "gotoVariation", "1-variation", 0);
   tag_eq( $sgf, "1-$name",
      W => "hp");

   sgf_func($sgf, "next", "2-$name");
   tag_eq( $sgf, "1-$name",
      B => "io");
   sgf_func($sgf, "gotoParent", $name);
   sgf_func($sgf, "gotoVariation", "2-variation", 1);
   tag_eq( $sgf, "2-$name",
      W => "hq");

   sgf_func($sgf, "next", "2-$name");
   tag_eq( $sgf, "2-$name",
      B => "hp");

   sgf_func($sgf, "next", "2-$name");
   tag_eq( $sgf, "2-$name",
      W => "ip",
      LB =>[$sgf->compose("fo","A")],
      C => "Some Comment ] with a needed escape");

   sgf_func($sgf, "next", "2-$name");
   tag_eq( $sgf, "2-$name",
      B => "iq");

   sgf_func($sgf, "next", "2-$name");
   tag_eq( $sgf, "2-$name",
      W => "hr");
}
