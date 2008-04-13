use Test::More tests => 18;                      # last test to print
use Games::SGF;
use Games::SGF::Go;
use Data::Dumper;

my $sgf = new Games::SGF(debug => 1);
my( $pt, $st, $mv );

ok( $pt = $sgf->point("aa"), "Make point");
ok( $sgf->isPoint($pt), "Check point");
ok( $sgf->point($pt) eq "aa", "Invert point");

ok( $st = $sgf->stone("aa"), "Make stone");
ok( $sgf->isStone($st), "Check stone");
ok( $sgf->stone($st) eq "aa", "Invert stone");

ok( $mv = $sgf->move("aa"), "Make move");
ok( $sgf->isMove($mv), "Check move");
ok( $sgf->move($mv) eq "aa", "Invert move");

$sgf = new Games::SGF::Go(debug => 1);
( $pt, $st, $mv ) = ();
my @cords;

ok( $pt = $sgf->point(27,12), "Make Go point");
ok( $sgf->isPoint($pt), "Check Go point");
@cords = $sgf->point($pt);
ok( ($cords[0] == 27 and $cords[1] == 12), "Invert Go point");

ok( $st = $sgf->stone(27,12), "Make Go stone");
ok( $sgf->isStone($st), "Check Go stone");
@cords = $sgf->stone($st);
ok( ($cords[0] == 27 and $cords[1] == 12), "Invert Go stone");

ok( $mv = $sgf->move(27,12), "Make Go move");
ok( $sgf->isMove($mv), "Check Go move");
@cords = $sgf->move($mv);
ok( ($cords[0] == 27 and $cords[1] == 12), "Invert Go move");

