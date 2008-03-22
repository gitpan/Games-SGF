use Test::More tests => 27;
use Games::SGF::Go;
use Data::Dumper;
require "t/sgf_test.pl";
my $sgf = new Games::SGF::Go();

sgf_ok($sgf, $sgf->readFile('t/sgf/go-1.sgf'), "Read File");
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
#sgf_func($sgf, "next", "Move 2");
#tag_eq( $sgf, "Move 2",
#  B => [[15,3]]);

sub test_moves {
   my $sgf = shift;
   my $name = shift;
   my(@moves) = @_;
   my $color = "B";
   for(my $i = 0; $i < @moves; $i++) {
      sgf_func($sgf, "next", "$i $name");
      tag_eq($sgf, "$i $name",
         $color => [$moves[$i]]);
      $color = $color eq 'B' ? 'W' : 'B';
   }
}
#print Dumper $sgf;
