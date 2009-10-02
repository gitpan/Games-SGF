use Test::More tests => 186;                      # last test to print
use Games::SGF;
use Data::Dumper;
use warnings;
require 't/sgf_test.pl';

my $sgf_in = <<SGF;
(;GM[1]FF[4]AP[qGo:1.5.4]ST[1]
SZ[19]HA[0]KM[5.5]PW[White]PB[Black]
AB[dp][ep][eq]AW[do][eo][fp][fq]PL[B]
;B[go]DO[];PL[W]
(
;W[hp];B[io]GB[1]
)
(
;W[hq];B[hp];W[ip]LB[fo:A]C[Some Comment \\]: colen for good messure
 with a needed escape]FG[]
;B[iq];W[hr]GW[2]
)
)
(;GM[1]FF[4]C[NextGame])
SGF

# create Parsers
my $parser1 = new Games::SGF(Warn => 0, Debug => 0);
#my $parser2 = new Games::SGF(Warn => 0, Debug => 0);

ok( $parser1, "Create Parser Object 1" );
#ok( $parser2, "Create Parser Object 2" );

# add tags to parsers
ok( $parser1->addTag('KM', $parser1->T_GAME_INFO, $parser1->V_REAL ), "addTag");
#ok( $parser2->addTag('KM', $parser2->T_GAME_INFO, $parser2->V_REAL ), "addTag");

my $parser2 = $parser1->clone;
ok( $parser2, "Create copy of Object 1");

# read in $sgf_in
ok( $parser1->readText($sgf_in), "Read Initial SGF Text");
# write it back out
ok($parser1->writeFile('test.sgf'), "Write the parsed Tree");

# read it in the second parser
ok($parser2->readFile('test.sgf'), "Read Second SGF Text");
#clean up the write test
unlink 'test.sgf' or die "Failed to unlink 'test.sgf':$!";
test_nav( $parser1, "parse1");
test_nav( $parser2, "parse2");
sub test_nav {
   my $sgf = shift;
   my $name = shift;
   my $notNext = shift;

   tag_eq( $sgf, $name,
      GM => [1],
      FF => [4],
      AP => [$sgf->compose("qGo","1.5.4")],
      ST => [1],
      SZ => [19],
      HA => [0],
      KM => [5.5],
      PW => ["White"],
      PB => ["Black"],
      AB => [  $sgf->stone("dp"),
               $sgf->stone("ep"),
               $sgf->stone("eq")
            ],
      AW => [  $sgf->stone("do"),
               $sgf->stone("eo"),
               $sgf->stone("fp"),
               $sgf->stone("fq")
            ],
      PL => $sgf->C_BLACK );
   #node_next($sgf, "1-$name");

   ok($sgf->next, "1-$name");
   tag_eq( $sgf, $name,
      B => $sgf->move("go"),
      DO => $sgf->empty );
   ok($sgf->next, "1-$name");
   tag_eq( $sgf, $name,
      PL => $sgf->C_WHITE);

   my ($num_var) = $sgf->variations;
   ok($num_var == 2, "number of variations");
   ok($sgf->gotoVariation(0), "1 - variation");
   tag_eq( $sgf, "1-$name",
      W => $sgf->move("hp"));

   ok($sgf->next, "2-$name");
   tag_eq( $sgf, "1-$name",
      B => $sgf->move("io"),
      GB => $sgf->DBL_NORM);
   ok($sgf->gotoParent, $name);
   ok($sgf->gotoVariation(1), "2-variation");
   tag_eq( $sgf, "2-$name",
      W => $sgf->move("hq"));

   ok($sgf->next, "2-$name");
   tag_eq( $sgf, "2-$name",
      B => $sgf->move("hp"));

   ok($sgf->next, "2-$name");
   tag_eq( $sgf, "2-$name",
      W => $sgf->move("ip"),
      LB => [$sgf->compose($sgf->point("fo"),"A")],
      C => ["Some Comment ]: colen for good messure
 with a needed escape"],
      FG => $sgf->empty);

   ok($sgf->next, "2-$name");
   tag_eq( $sgf, "2-$name",
      B => $sgf->move("iq"));

   ok($sgf->next, "2-$name");
   tag_eq( $sgf, "2-$name",
      W => $sgf->move("hr"),
      GW => $sgf->DBL_EMPH
   );
   
   # move to prev node and check
   ok($sgf->prev, "prev-$name");
   tag_eq( $sgf, "2-$name",
      B => $sgf->move("iq"));

   ok($sgf->nextGame, "nextgame-$name");
   tag_eq( $sgf, "nextGame-$name",
      GM => 1,
      FF => 4,
      C => "NextGame");

   ok($sgf->prevGame, "prevGame-$name");
   test_nav($sgf, "retest-$name", 1) unless $notNext;
}
