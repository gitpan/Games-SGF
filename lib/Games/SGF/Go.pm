package Games::SGF::Go;

use strict;
use warnings;
require Games::SGF;

=head1 NAME

Games::SGF::GO - A Go Specific SGF Parser

=head1 VERSION

Version 0.02 Alpha Release

=cut

our( @ISA ) = ('Games::SGF');
our( $VERSION ) = 0.02;

=head1 SYNOPSIS

  use Games::SGF::Go;

  my $sgf = new Games::SGF::Go;

  $sgf->readFile('somegame.sgf');

  # fetch Properties
  my $komi = $sgf->property('KM');
  my $handicap = $sgf->property('HA');

  # move to next node
  $sgf->next;

  # get a move
  my $move = $sgf->property('B');
  
  # add it to a board
  
  $board[ $move->[0] ][ $move->[1] ] = 'B';

=head1 DISCRIPTION

Games::SGF::Go Extends L<Games::SGF> for the game specifics of Go. These
include adding the tags 'TB', 'TW', 'HA', and 'KM'. It will also parse and
check the stone, move, and point types.

The stone, move and point types will be returned as an array ref containing
the position on the board.

You can set application specific tags using L<Games::SGF/setTag>. All the
callbacks to L<Games::SGF> have been set and thus can't be reset.

All other methods from L<Games::SGF/METHODS> can be used as you normally would.

=head1 METHODS

=head2 new

  my $sgf = new Games::SGF::Go;

This will create the Games::SGF::Go object.

=cut

sub new {
   my $inv = shift;
   my $class = ref $inv || $inv;
   my $self = $class->SUPER::new(@_);

   # add Go Tags

   # Territory Black
   $self->addTag('TB', $self->T_NONE, $self->V_POINT,
            $self->VF_EMPTY | $self->VF_LIST | $self->VF_OPT_COMPOSE);

   # Territory White
   $self->addTag('TW', $self->T_NONE, $self->V_POINT,
            $self->VF_EMPTY | $self->VF_LIST | $self->VF_OPT_COMPOSE);

   # Handicap
   $self->addTag('HA', $self->T_GAME_INFO, $self->V_NUMBER);

   # Komi
   $self->addTag('KM', $self->T_GAME_INFO, $self->V_REAL);

   # add Go CallBacks

   # Read
   $self->setPointRead(\&_readPoint);
   $self->setStoneRead(\&_readPoint);
   $self->setMoveRead( sub {
      if( $_[0] eq "" ) {
         return "";
      } else {
         return &_readPoint($_[0]);
      }
   });

   # Check
   $self->setPointCheck(\&_checkPoint);
   $self->setStoneCheck(\&_checkPoint);
   $self->setMoveCheck( sub {
      if( $_[0] eq "" ) {
         return 1;
      } else {
         return &_checkPoint($_[0]);
      }
   });

   # Write
   $self->setPointWrite(\&_writePoint);
   $self->setStoneWrite(\&_writePoint);
   $self->setMoveWrite(\&_writePoint);
   

   return bless $self, $class; # reconsecrate
}

sub _readPoint {
   my $text = shift;
   my( @cord ) = split //, $text;
   
   foreach( @cord ) {
      if( $_ ge 'a' and $_ le 'z' ) {
         $_ = ord($_) - ord('a'); # 0 - 25
      } elsif( $_ ge 'A' and $_ le 'Z' ) {
         $_ = ord($_) - ord('A') + 26; # 26 - 51
      } else {
         #error;
      }
   }
   return [@cord];
}

sub _checkPoint {
   my $struct = shift;
   if( ref $struct ne 'ARRAY' ) {
      return 0;
   }
   foreach( @$struct ) {
      if( /\D/ ) {
         return 0;
      }
      if( $_ < 0 or $_ > 52 ) {
         return 0;
      }
   }
   return 1;
}
sub _writePoint {
   my $struct = shift;
   my $text = "";
   foreach(@$struct) {
      if( $_ < 26 ) {
         $text .= chr( ord('a') + $_ );
      } else {
         $text .= chr( ord('A') + $_ );
      }
   }
   return $text;
}
1;
__END__

=head1 ALSO SEE

L<Games::SGF>

L<http://www.red-bean.com/sgf>

L<Games::Goban>

L<Games::Go::SGF>

=head1 AUTHOR

David Whitcomb, C<< <whitcode at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-sgf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-SGF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.
