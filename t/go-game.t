use Test::More tests => 27;
use Games::SGF::Go;
require "t/sgf_test.pl";
my $sgf = new Games::SGF::Go();

ok( $sgf->readFile('t/sgf/go-1.sgf'), "Read File");
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
   CA => "UTF-8");
test_moves( $sgf, "Move",
   [15,3],
   [3,15],
   [15,15],
   [3,2],
   [2,9],
   [16,13],
   [16,11]
);
