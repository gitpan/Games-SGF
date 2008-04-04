use Test::More tests => 67;
use Games::SGF::Go;
use Data::Dumper;
require "t/sgf_test.pl";

my $sgf_in = <<SGF;
(;GM[1]FF[4]AP[qGo:1.5.4]ST[1]
SZ[19]HA[0]KM[6.5]OT[20 per move]
PW[GNU Go 3.6]PB[Unknown]RE[Void]
CA[UTF-8]AW[aa][ab][ac]AE[ab]
;B[pd]BL[20]OB[1]
;W[dp]WL[20]OW[1]
;B[pp]BL[20]OB[1]
;W[dc]WL[20]OW[1]
;B[cj]BL[20]OB[1]
;W[qn]WL[20]OW[1]
;B[ql]BL[20]OB[1]
;W[];B[])
SGF
my $sgf = new Games::SGF::Go(debug =>1);

ok( $sgf->readText($sgf_in), "Read SGF");
nav($sgf);
my $sgf_out;
ok($sgf_out = $sgf->writeText, "writing SGF");
$sgf = new Games::SGF::Go(debug => 1);
ok( $sgf->readText($sgf_out), "Read SGF Out");
nav($sgf);


sub nav {
   my $sgf = shift;
   tag_eq( $sgf, "Root Node",
      GM => 1,
      FF => 4,
      AP => [$sgf->compose("qGo","1.5.4")],
      ST => 1,
      SZ => 19,
      HA => 0,
      KM => 6.5,
      OT => "20 per move",
      PW => "GNU Go 3.6",
      PB => "Unknown",
      RE => "Void",
      CA => "UTF-8",
      AW => [  $sgf->stone(0,0),
               $sgf->stone(0,1),
               $sgf->stone(0,2) ],
      AE => $sgf->point(0,1),
   );
   test_moves( $sgf, "Move",
      $sgf->move(15,3),
      $sgf->move(3,15),
      $sgf->move(15,15),
      $sgf->move(3,2),
      $sgf->move(2,9),
      $sgf->move(16,13),
      $sgf->move(16,11),
      $sgf->pass,
      $sgf->pass
   );
}
