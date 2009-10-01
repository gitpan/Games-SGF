use Test::More tests => 34;
use Games::SGF;
use Games::SGF::Util;
use Data::Dumper;
require "t/sgf_test.pl";

my $sgf_in = <<SGF;
(;B[aa]C[Keep]
 ;W[ab]C[Some]
 (;B[ac]C[body])
 (;W[dd]C[Keep])
)
SGF
my $u = new Games::SGF::Util();
ok( not( $u), "Correctly failed to create util object");

my $sgf = Games::SGF->new();

ok( $sgf->readText($sgf_in), "Read File");
nav( $sgf, "Keep", "Some","body","Keep");

my $util = Games::SGF::Util->new($sgf);
$u = Games::SGF::Util->new($sgf);
$util->filter( "C" , sub { $_[0] =~ s/ee//g; return $_[0];} );
nav( $util->sgf(), "Kp", "Some","body","Kp");

$u->sgf($util->sgf);
$u->filter( "C" , sub { return $_[0] eq "body" ? undef : $_[0];} );
nav( $u->sgf(), "Kp", "Some",undef,"Kp");

$u->filter( "C" , undef );
nav( $u->sgf());

sub nav {
   my $sgf = shift;
   $sgf->gotoRoot;
   my( @c ) = @_;

   tag_eq( $sgf, "Root Node",
      B => $sgf->move("aa"),
      C => shift @c
   );
   $sgf->next;

   tag_eq( $sgf, "Second Node",
      W => $sgf->move("ab"),
      C => shift @c
   );
   $sgf->gotoVariation(0);

   tag_eq( $sgf, "Third Node",
      B => $sgf->move("ac"),
      C => shift @c
   );
   $sgf->gotoParent;
   $sgf->gotoVariation(1);

   tag_eq( $sgf, "Forth Node",
      W => $sgf->move("dd"),
      C => shift @c
   );
}
