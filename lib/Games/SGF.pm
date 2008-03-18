package Games::SGF;

use strict;
use warnings;
use Carp;
use enum qw( 
         :C_=1 BLACK WHITE
         :DBL_=1 NORM EMPH
         :V_=1 NONE NUMBER REAL DOUBLE COLOR SIMPLE_TEXT TEXT POINT MOVE STONE
         :BITMASK :VF_=1 EMPTY LIST OPT_COMPOSE
         :T_=1 MOVE SETUP ROOT GAME_INFO NONE
         :A_=1 NONE INHERIT
         );

=head1 NAME

Games::SGF - A general SGF parser

=head1 VERSION

Version 0.01 first release

=cut


our $DEBUG = 1;
our $VERSION = 0.01;
our $errstr;

my( %ff4_properties ) = (
   # general move properties
   'B' => { 'type' => T_MOVE, 'value' => V_MOVE },
   'BL' => { 'type' => T_MOVE, 'value' => V_REAL },
   'BM' => { 'type' => T_MOVE, 'value' => V_DOUBLE },
   'DO' => { 'type' => T_MOVE, 'value' => V_NONE },
   'IT' => { 'type' => T_MOVE, 'value' => V_NONE },
   'KO' => { 'type' => T_MOVE, 'value' => V_NONE },
   'MN' => { 'type' => T_MOVE, 'value' => V_NUMBER },
   'OB' => { 'type' => T_MOVE, 'value' => V_NUMBER },
   'OW' => { 'type' => T_MOVE, 'value' => V_NUMBER },
   'TE' => { 'type' => T_MOVE, 'value' => V_DOUBLE },
   'W' => { 'type' => T_MOVE, 'value' => V_MOVE },
   'WL' => { 'type' => T_MOVE, 'value' => V_REAL },

   # general setup properties
   'AB' => { 'type' => T_SETUP, 'value' => V_STONE, 'value_flags' => VF_LIST },
   'AE' => { 'type' => T_SETUP, 'value' => V_POINT, 'value_flags' => VF_LIST },
   'AW' => { 'type' => T_SETUP, 'value' => V_STONE, 'value_flags' => VF_LIST },
   'PL' => { 'type' => T_SETUP, 'value' => V_COLOR, 'value_flags' => VF_LIST },

   # genreal none inherited properties
   'DD' => { 'type' => T_NONE, 'value' => V_POINT, 
             'value_flags' => VF_EMPTY | VF_LIST | VF_OPT_COMPOSE,
             'attrib' => A_INHERIT },
   'PM' => { 'type' => T_NONE, 'value' => V_NUMBER, 'attrib' => A_INHERIT },
   'VW' => { 'type' => T_NONE, 'value' => V_POINT,
             'value_flags' => VF_EMPTY | VF_LIST | VF_OPT_COMPOSE, 
             'attrib' => A_INHERIT },

   # general none properties
   'AR' => { 'type' => T_NONE, 'value' => [V_POINT,V_POINT], 
             'value_flags' => VF_LIST },
   'C' => { 'type' => T_NONE, 'value' => V_TEXT },
   'CR' => { 'type' => T_NONE, 'value' => V_POINT,
             'value_flags' => VF_LIST | VF_OPT_COMPOSE },
   'DM' => { 'type' => T_NONE, 'value' => V_DOUBLE },
   'FG' => { 'type' => T_NONE, 'value' => [V_NUMBER,V_SIMPLE_TEXT],
             'value_flags' => VF_EMPTY },
   'GB' => { 'type' => T_NONE, 'value' => V_DOUBLE },
   'GW' => { 'type' => T_NONE, 'value' => V_DOUBLE },
   'HO' => { 'type' => T_NONE, 'value' => V_DOUBLE },
   'LB' => { 'type' => T_NONE, 'value' => [V_POINT,V_SIMPLE_TEXT],
             'value_flags' => VF_LIST },
   'LN' => { 'type' => T_NONE, 'value' => [V_POINT,V_POINT],
             'value_flags' => VF_LIST },
   'MA' => { 'type' => T_NONE, 'value' => V_POINT,
             'value_flags' => VF_EMPTY | VF_LIST | VF_OPT_COMPOSE },
   'N' => { 'type' => T_NONE, 'value' => V_SIMPLE_TEXT },
   'SL' => { 'type' => T_NONE, 'value' => V_POINT, 
             'value_flags' => VF_LIST | VF_OPT_COMPOSE },
   'SQ' => { 'type' => T_NONE, 'value' => V_POINT,
             'value_flags' => VF_LIST | VF_OPT_COMPOSE },
   'TR' => { 'type' => T_NONE, 'value' => V_POINT, 
             'value_flags' => VF_LIST | VF_OPT_COMPOSE },
   'UC' => { 'type' => T_NONE, 'value' => V_DOUBLE },
   'V' => { 'type' => T_NONE, 'value' => V_REAL },

   # general root properties
   'AP' => { 'type' => T_ROOT, 'value' => [V_SIMPLE_TEXT, V_NUMBER] },
   'CA' => { 'type' => T_ROOT, 'value' => V_SIMPLE_TEXT },
   'FF' => { 'type' => T_ROOT, 'value' => V_NUMBER },
   'GM' => { 'type' => T_ROOT, 'value' => V_NUMBER },
   'ST' => { 'type' => T_ROOT, 'value' => V_NUMBER },
   'SZ' => { 'type' => T_ROOT, 'value' => V_NUMBER, 
             'value_flags' => VF_OPT_COMPOSE},

   # general game-info properties
   'AN' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'BR' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'BT' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'CP' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'DT' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'EV' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'GC' => { 'type' => T_GAME_INFO, 'value' => V_TEXT },
   'GN' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'ON' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'OT' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'PB' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'PC' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'PW' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'RE' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'RO' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'RU' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'SO' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'TM' => { 'type' => T_GAME_INFO, 'value' => V_REAL },
   'US' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'WR' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
   'WT' => { 'type' => T_GAME_INFO, 'value' => V_SIMPLE_TEXT },
);

=head1 SYNOPSIS

  use Games::SGF;

  my $sgf = new Games::SGF();

  $sgf->setStoneRead( sub { "something useful"} );
  $sgf->setMoveRead( sub { "something useful"} );
  $sgf->setPointRead( sub { "something useful"} );

  $sgf->addTag('KM', $sgf->T_GAME_INFO, $sgf->V_REAL );
  $sgf->parseFile("015-01.sgf");

=head1 DISCRIPTION

Games::SGF is a general Smart Game Format Parser. It parses
the file, and checks the properties against the file format 4
standard. No game specific features are implemented.

It is designed so that the user can tell it how to handle new
tags. It also allows the user to set callbacks to parse Stone,
Point, and Move types. These are types are game specific.

SGF file contains 1 or more game trees. Each game tree consists of a sequence
of nodes followed by a sequence of branches. Each branch also consists a
sequence of nodes followed by a sequence of branches.

Each node contains a set of properties. Each property has a L</Type>, L</Value Type>,
L</Flags>, and an L<Attribute>. The Type specifies where and when an attribute may
bew used. A Value Type says what type of value it contains. Flags are used to
specify variuos properties, such as being a list, or if the field is empty.
Attributes specify other behavior.

Also see: L<http://www.red-bean.com/sgf>

=head1 METHODS

=head2 new

  new Games::SGF();

Creates a SGF object, there may be options defined latter,
but as of right now takes no paramaters.

=cut

sub new {
   my $inv = shift;
   my $class = ref( $inv) || $inv;
   my( %opts ) = @_;
   my $self = {};
   # stores added tags
   $self->{'tags'} = {};
   # stores stone, point, move handling subroutines
   $self->{'stoneSub'} = undef;
   $self->{'pointSub'} = undef;
   $self->{'moveSub'} = undef;
   $self->{'game'} = undef; 
   $self->{'collection'} = undef; 
   $self->{'parents'} = undef; 
   $self->{'node'} = undef; 
   return bless $self, $class;
}

=head2 readText

  $sgf->readText($text);

This takes in a SGF formated string and parses it.

=cut

sub readText {
   my $self = shift;
   my $text = shift;
   if( not $self->_read($text) ) {
      # no games read error
      # $errstr = "No Games read in by readText\n";
      return undef;
   } else {
      $self->{'game'} = 0; # first branch
      $self->{'parents'} = [$self->{'collection'}->[0]]; # root branch is root
      $self->{'node'} = 0; # first node
   }
   return 1;
}

=head2 readFile

  $sgf->readFile($file);

This will open the passed file, read it in then parse it.

=cut

sub readFile {
   my $self = shift;
   my $filename = shift;
   my $text;
   my $fh;
   if( not open $fh, "<", $filename ) {
      $errstr =  "Failed to open File '$filename': $!\n";
      return undef;
   }
   if(read( $fh, $text, -s $filename) == 0 ) {
      $errstr = "Failed to read File '$filename': $!\n";
   }
   close $fh;
   return $self->readText($text) ;
}

=head2 writeText

  $sgf->writeText;

Will return the current collection in SGF form;

=cut

sub writeText {
   my $self = shift;
   my $text = "";
   foreach my $game ( @{$self->{'collection'}}) {
      $text .= $self->_write($game);
      $text .= "\n";
   }
   #foreach game
   #  write branch
   #  write branch: write sequences, write other branches
   return $text;
}
sub _write_tags {
   my $self = shift;
   my $hash = shift;
   my $text = "";
   foreach my $tag ( keys %$hash ) {
      my( @values ) = @{$hash->{$tag}};
      $text .= $tag;
      if( @values == 0 ) {
         $text .= "[]";
      } else {
         foreach my $val( @values ) {
            $text .= "[";

            # add value
            if( $self->_maybeComposed($tag) and ref $val eq 'ARRAY' ) {
               my $val1 = $self->_typeWrite($tag,0,$val->[0]);
               return undef if not defined $val1;
               my $val2 = $self->_typeWrite($tag,1,$val->[1]);
               return undef if not defined $val2;
               $text .= $val1. ":" . $val2;
            } else {
               my $val = $self->_typeWrite($tag,0,$val);
               return undef if not defined $val;
               $text .= $self->_typeWrite($tag,0,$val);
            }
            $text .= "]"
         }
         $text .= "\n"; # add some white space to make it easier to read
      }
   }
   return $text;
}


sub _write {
   my $self = shift;
   my $branch = shift;
   my $text = "(";
   # foreach node ";", tags
   for( my $i = 0; $i < @{$branch->[0]}; $i++ ) {
      $text .= ";"; # starts the node

      # write tags in main tree
      $text .= $self->_write_tags($branch->[0]->[$i]);

      # write tags from inherited tree
      if( exists $self->{'inherited'}->{$branch}->{$i} ) {
         $text .= $self->_write_tags($self->{'inherited'}->{$branch}->{$i});
      }
   }

   # write variations
   for( my $i = 0; $i < @{$branch->[1]}; $i++ ) {
      $text .= $self->_write($branch->[1]->[$i]);
      #$text .= "\n"; # white space for readablity
   }

   $text .= ")"; # finish branch
   $text .= "\n"; # white space for readablity

   return $text;
}

   # foreach variation
   #  _write $var

=head2 writeFile

  $sgf->writeFile($filename);

Will write the current game collection to $filename.

=cut

sub writeFile {
   my $self = shift;
   my $filename = shift;
   my $text;
   my $fh;
   if( not open $fh, ">", $filename ) {
      $errstr =  "Failed to open File '$filename': $!\n";
      return undef;
   }
   print $fh $self->writeText;
   close $fh;
   return 1;
}

=head2 addTag

  $sgf->addTag($tagname, $type, $value_type, $flags, $attribute);

This add a new tag to the parsing engine. This needs to called before the read
or write commands are called. This tag will not override the FF[4] standard
properties, or already defined properties.

The C<$tagname> is the name of the tag which will be read in, thus if you want
to be able to read AAA[...] from an SGF file the tagname needs to be "AAA".

The C<$type> needs to be choosen from the L</Type> list below. Defaults to
C<T_NONE>.

The C<$value_type> needs to be choosen from the L</Type> list below.
Defaults to C<V_TEXT>.

The C<$flags> are from the L</Flags> List. Defaults to C<VF_EMPTY | VF_LIST>.

The C<$attribute> is from the L</Attribute> List. Defaults to C<A_NONE>.

=cut

sub addTag {
   my $self = shift;
   my $tagname = shift;
   if( exists $self->{'tags'}->{$tagname} ) {
      $errstr = "addTag( $tagname ); FAILED : $tagname already exists\n";
      return undef;
   }
   $self->{'tags'}->{$tagname}->{'type'} = shift;
   $self->{'tags'}->{$tagname}->{'value'} = shift;
   $self->{'tags'}->{$tagname}->{'value_flags'} = shift;
   $self->{'tags'}->{$tagname}->{'attrib'} = shift;

   return 1;
}

=head2 setPointRead

=cut


sub setPointRead {
   my $self = shift;
   my $coderef = shift;
   if( ref $coderef eq 'CODE' ) {
      $self->{'pointRead'} = $coderef;
   } else {
      $errstr = "Point Read subroutine was not a subroutine reference\n";
      return undef;
   }
   return 1;
}

=head2 setMoveRead

=cut

sub setMoveRead {
   my $self = shift;
   my $coderef = shift;
   if( ref $coderef eq 'CODE' ) {
      $self->{'moveRead'} = $coderef;
   } else {
      $errstr =  "Move Read subroutine was not a subroutine reference\n";
      return undef;
   }
   return 1;
}

=head2 setStoneRead

  $sgf->setPointRead(\&coderef);
  $sgf->setMoveRead(\&coderef);
  $sgf->setStoneRead(\&coderef);

These call backs are called when a properties value needs to be parsed.
It takes in a string, and returns a structure of some type. Here is a
possible example for a Go point callback:

  sub parsepoint {
     my $value = shift;
     my( $x, $y) = split //, $value;
     return [ ord($x) - ord('a'), ord($y) - ord('a') ];
  }
  # then somewhere else
  $sgf->setPointParse( \&parsepoint );

Note: that you should do more then this in practice, but it gets the
across.

=cut

sub setStoneRead {
   my $self = shift;
   my $coderef = shift;
   if( ref $coderef eq 'CODE' ) {
      $self->{'stoneRead'} = $coderef;
   } else {
      $errstr =  "Stone Read subroutine was not a subroutine reference\n";
      return undef;
   }
   return 1;
}


=head2 setPointCheck

=cut


sub setPointCheck {
   my $self = shift;
   my $coderef = shift;
   if( ref $coderef eq 'CODE' ) {
      $self->{'pointCheck'} = $coderef;
   } else {
      $errstr =  "Point Check subroutine was not a subroutine reference\n";
      return undef;
   }
   return 1;
}

=head2 setMoveCheck

=cut

sub setMoveCheck {
   my $self = shift;
   my $coderef = shift;
   if( ref $coderef eq 'CODE' ) {
      $self->{'moveCheck'} = $coderef;
   } else {
      $errstr =  "Move Check subroutine was not a subroutine reference\n";
      return undef;
   }
   return 1;
}

=head2 setStoneCheck

  $sgf->setPointCheck(\&coderef);
  $sgf->setMoveCheck(\&coderef);
  $sgf->setStoneCheck(\&coderef);

This callback is called when a parameter is stored. The callback takes
the structure passed to setProperty, or component if composed, and returns
true if it is a valid structure.

An Example of a stone check for go is as follows:

  sub stoneCheck {
     my $stone = shift;
     if( ref $stone eq 'ARRAY' and @$stone == 2
            and $stone->[0] > 0 and $stone->[1] > 0 ) {
         return 1;
     } else {
         return 0;
     }
  }

=cut

sub setStoneCheck {
   my $self = shift;
   my $coderef = shift;
   if( ref $coderef eq 'CODE' ) {
      $self->{'stoneCheck'} = $coderef;
   } else {
      $errstr =  "Stone Check subroutine was not a subroutine reference\n";
      return undef;
   }
   return 1;
}

=head2 setPointWrite

=cut


sub setPointWrite {
   my $self = shift;
   my $coderef = shift;
   if( ref $coderef eq 'CODE' ) {
      $self->{'pointWrite'} = $coderef;
   } else {
      $errstr =  "Point Write subroutine was not a subroutine reference\n";
      return undef;
   }
   return 1;
}

=head2 setMoveWrite

=cut

sub setMoveWrite {
   my $self = shift;
   my $coderef = shift;
   if( ref $coderef eq 'CODE' ) {
      $self->{'moveWrite'} = $coderef;
   } else {
      $errstr =  "Move Write subroutine was not a subroutine reference\n";
      return undef;
   }
   return 1;
}

=head2 setStoneWrite

  $sgf->setPointWrite(\&coderef);
  $sgf->setMoveWrite(\&coderef);
  $sgf->setStoneWrite(\&coderef);

This callback is called when a parameter is written in text format. The callback takes
the structure passed to setProperty, or component if composed, and returns
the text string which will be stored.

An Example of a stone check for go is as follows:

  sub stoneWrite {
     my $stone = shift;
     my @list = ('a'..'Z','A'..'Z');
     return $list[$stone->[0] - 1] . $list[$stone->[1] - 1];
  }

=cut

sub setStoneWrite {
   my $self = shift;
   my $coderef = shift;
   if( ref $coderef eq 'CODE' ) {
      $self->{'stoneWrite'} = $coderef;
   } else {
      $errstr =  "Stone Write subroutine was not a subroutine reference\n";
      return undef;
   }
   return 1;
}

=head2 nextGame

  $sgf->nextGame;

Sets the node pointer to the next game in the Collection. If the current
game is the last game then returns 0 otherwise 1.

=head2 prevGame;

  $sgf->prevGame;

Sets the node pointer to the prevoius game in the Collection. If the current
game is the first game then returns 0 otherwise 1.

=cut

sub nextGame {
   my $self = shift;
   my $lastGame = @{$self->{'collection'}} - 1;
   my $curGame = $self->{'game'}; # first element is the address game num
   if( $curGame >= $lastGame ) { # on last game
      return 0;
   } else {
      $self->{'game'}++;
      return 1;
   }
}

sub prevGame {
   my $self = shift;
   my $curGame = $self->{'game'}; # first element is the address game num
   if( $curGame <= 0 ) { # on first game
      return 0;
   } else {
      $self->{'game'}--;
      return 1;
   }
}

=head2 addGame

  $self->addGame;

This will add a new game to the collection with the root node added. The
current node pointer will be set to the root node of the new game.

Returns true on success.



=cut

sub addGame {
   my $self = shift;
   my $newGame = [[],[]];
   push @{$self->{'collection'}}, $newGame;
   $self->{'game'} = @{$self->{'collection'}} - 1;
   $self->{'parents'} = [$newGame];
   $self->{'node'} = -1;
   if( $self->addNode() ) {
      return 1;
   } else {
      return undef;
   }
}

=head2 next

  $sgf->next;

Moves the node pointer ahead one node.

Returns 0 if it is the last node in the branch, otherwise 1

=cut

sub next {
   my $self = shift;
   my $branch = $self->_getBranch;

   if( $self->{'node'} < @{$branch->[0]} - 1 ) {
      return 0;
   } else {
      $self->{'node'}++;
      return 1;
   }
}

=head2 prev

  $sgf->prev;

Moves the node pointer back one node.

Returns 0 if first node in the branch and 1 otherwise

=cut

sub prev {
   my $self = shift;
   if( $self->{'node'} > 0 ) {
      $self->{'node'}--;
      return 1;
   } else {
      return 0;
   }
}

=head2 variations

  $sgf->variations;

Returns the number of variations on this branch.

=cut

sub variations {
   my $self = shift;
   my $branch = $self->_getBranch;
   return scalar @{$branch->[1]};
}

=head2 gotoVariation

  $sgf->gotoVariation($n);

Goes to the first node of the specified Variation. If it returns 4
that means that there is variations C<0..3>,

Returns 1 on success and 0 on Failure.

=cut

sub gotoVariation {
   my $self = shift;
   my $n = shift;
   my $branch = $self->_getBranch;
   if( $n >= @{$branch->[1]} ) {
      return 0;
   } else {
      push @{$self->{'parents'}}, $branch->[1]->[$n];
      return 1;
   }
}

=head2 gotoParent

  $sgf->gotoParent;

Will move the node pointer to the last node of the parent branch. This will
fail if you already on the root branch for the current game.

Returns 1 on success or 0 on failure.

=cut


sub gotoParent {
   my $self = shift;
   if( @{$self->{'parents'}} > 1 ) {
      pop @{$self->{'parents'}};
      my $branch = $self->_getBranch;
      $self->{'node'} = @{$branch->[0]} - 1;
      return 1;
   } else {
      return 0;
   }
}

=head2 addNode

  $sgf->addNode;

Adds node end of the current branch. It will fail if there is
any variations on this branch.

Returns 1 on success and 0 on Failure.

=cut

sub addNode {
   my $self = shift;
   my $branch = $self->_getBranch;
   my $node = {};
   if( @{$branch->[1]} ) {
      $errstr = "Can't add Node since there exists a variation\n";
      return undef;
   }
   push @{$branch->[0]}, $node;
   $self->{'node'} = @{$branch->[0]} - 1;
   return 1;
}

=head2 addVariation

  $sgf->addVariation;

Adds a new variation onto this branch. The current branch will be changed to
this new variation. It will then add the first node for this variation.

Returns 1 on sucess 0 on Failure.

=cut

sub addVariation {
   my $self = shift;
   my $branch = $self->_getBranch();
   my $tmp_node = $self->{'node'};
   my $var = [[],[]];
   push @{$branch->[1]}, $var;
   push @{$self->{'parents'}}, $var;
   $self->{'node'} = -1; # there are no nodes in the variation currently
   if( $self->addNode ) {
      return 1;
   } else {
      # undo what has been done
      # return to original state
      pop @{$branch->[1]};
      pop @{$self->{'parents'}};
      $self->{'node'} = $tmp_node;
      return 0;
   }
}

=head2 removeNode

  $sgf->removeNode;

Removes last node from the current Branch, will fail if there
is any variations on this branch

Returns 1 on success and 0 on Failure.

=cut

sub removeNode {
   my $self = shift;
   my $branch = $self->{'parents'}->[@{$self->{'parents'}} - 1 ];
   my $node = {};
   if( @{$branch->[1]} ) {
      return 0;
   }
   pop @{$branch->[0]};
   $self->{'node'} = @{$branch->[0]} - 1;
   return 1;
}

=head2 removeVariation

  $sgf->removeVariation($n);

This will remove the C<$n> variation from the branch. If you have 
variations C<0..4> and ask it to remove variation C<1> then the 
indexs will be C<0..3>.

Returns 1 on sucess 0 on Failure.

=cut

sub removeVariation {
   my $self = shift;
   my $n = shift;
   my $branch = $self->_getBranch();
   if( $n > 0 and $n < @{$branch->[1]} ) {
      splice @{$branch->[1]}, $n, 1;
      return 1;
   } else {
      return 0;
   }
}

=head2 splitBranch

  $sgf->splitBranch($n);

This will split the current branch into 2 branches, so that the last part of
the branch will be a variation of the first portion. C<$n> will be the first
node in the next variation.

Your node pointer will be the last node first branch. For Example say the 
branch you are on has nodes C<0..9> and you want to split it on node C<5>
will give the first branch having nodes C<0..4> having one variation containing
nodes C<5..9> and the variations of the original branch. Your node pointer
will point to node C<4>

This is used for adding a variation of move C<$n>:

  $sgf->splitBranch($n);
  $sgf->addVariation;
  $sgf->addNode;
  # set some node properties

The above code will add a variation on the a node in the middle of a node
sequence in a branch.

Returns 1 on success and 0 on Failure.

=cut

sub splitBranch {
   my $self = shift;
   my $n = shift;
   my $new_branch = [[],[]];
   my $branch = $self->_getBranch();
   if( $n > 0 and $n < @{$branch->[0]} ) {
      $new_branch->[0] = [splice @{$branch->[0]}, 0, $n];
      $new_branch->[1] = [$branch];
      pop @{$self->{'parents'}};
      push @{$self->{'parents'}}, $new_branch;
      $self->{'node'} = $n - 1;
      return 1;
   } else {
      return 0;
   }
}

=head2 property

  my $array_ref = $sgf->property( $value );
  my $didSave = $sgf->property( $value , @values );

This is used to read and set properties on the current node. Will prevent T_MOVE
and T_SETUP types from mixing. Will prevent writing T_ROOT tags to any location
other then the root node. Will Lists from being stored in non list tags. Will
prevent invalid structures from being stored.

=cut

#TODO use _setProperty and _getProperty
#
#  returns 0 on error
#  returns 1 on successful set
#  returns $arrref on successful get
sub property {
   my $self = shift;
   my $tag = shift;
   my( @values ) = @_;
   if( @values == 0 ) {
      #get
      return $self->getProperty($tag);
   } else {
      #set
      return $self->setProperty($tag,@values);
   }
}

=head2 getProperty

  my $array_ref = $sgf->getProperty($tag);
  if( $array_ref ) {
      # sucess
      foreach my $value( @$array_ref ) {
          # do something
      }
  } else {
      # failure
  }

Will fetch the the $tag value stored in the current node.

=cut

sub getProperty {
   my $self = shift;
   my $tag = shift;

   my $branch = $self->_getBranch;
   my $node = $self->_getNode;
   my $attri = $self->_getTagAttribute($tag);

   if( $attri == A_INHERIT ) {
      # use 'inherited hash'
      my $closest = undef;
      foreach(@{$self->{'parents'}}) {
         if( exists $self->{'inherited'}->{$_} ) {
            $closest = $_;
         }
      }
      if( $closest == undef ) {
         # none found
         return 0;
      } elsif( $closest == $branch )  {
         # find greatest node less then or equal to $self->{'node'}
         my $n;
         for( $n = $self->{'node'}; $n >= 0; $n--) {
            if( exists $self->{'inherited'}->{$closest}->{$n}->{$tag} ) {
               return $self->{'inherited'}->{$closest}->{$n}->{$tag};
            }
         }
         return 0;
      } else {
         # find greastest node
         my $max = -1;
         foreach( keys %{$self->{$closest}} ) {
            $max = $_ if $_ > $max;
         }
         if( $max > 0 ) {
            return $self->{$closest}->{$max}->{$tag};
         } else {
            return 0;
         }
      }
   } else {
      if( exists $node->{$tag} ) {
         return $node->{$tag};
      } else {
         # non existent $tag
         return 0;
      }
   }
}

=head2 setProperty

  fail() unless $sgf->setProperty($tag,@values);

Sets the the $tag value of the current node to @values. This method does
a series of sanity checks before attempting to write. It will fail if any
of the following are true:

=over

=item @values > 0 and is not a list

=item $tag is of type T_ROOT but the current node is not the root node

=item $tag is a T_MOVE or T_SETUP and the other type is already present in the node

=item @values are invalid type values

=item unseting a value that is not set.

=back

If @values is not passed then it will remove the property from the node.
This is not the same as setting to a empty value.

  $sgf->setProperty($tag); # will unset the $tag
  $sgf->setProperty($tag, "" ); # will set to an empty value

=cut

sub setProperty {
   my $self = shift;
   my $tag = shift;
   my( @values ) = @_;
   my $isUnSet = (scalar @values == 0) ? 1 : 0; # is unset if empty

   my $branch = $self->_getBranch;
   my $node = $self->_getNode;


   my $ttype = $self->_getTagType($tag);
   my $vtype = $self->_getTagValueType($tag);
   my $flags = $self->_getTagFlags($tag);
   my $attri = $self->_getTagAttribute($tag);

   # reasons to not set the property
   # set list values only if VF_LIST
   if( @values > 1 and not $vtype & VF_LIST ) {
      $errstr = "Can't set list for non VF_LIST: ($tag)\n";
      return 0;
   }
   # can set T_ROOT if you are at root
   if( $ttype == T_ROOT and  (@{$self->{'parents'}} != 1 or $self->{'node'} != 0) ) {
      $errstr = "Can't set T_ROOT($tag) when not at root( Parents: "
                  . scalar(@{$self->{'parents'}}) . " Node: " . $self->{'node'} . "\n";
      return 0;
   }
   # don't set T_MOVE or T_SETUP if other is present
   #  ASSUMPTION: No Inherited property is a T_MOVE or T_SETUP
   my $tnode = undef;
   foreach( keys %$node ) {
      my $tag_type = $self->_getTagType($_);
      if( $tnode ) {
         if( ($tnode == T_SETUP and $tag_type == T_MOVE)
               or ($tnode == T_MOVE and $tag_type == T_SETUP) ) {
            $errstr = "Can't mix T_SETUP and T_MOVES\n";
            return 0;
         } elsif( $tnode == undef
               and ($tag_type == T_MOVE or $tag_type == T_SETUP) ) {
            $tnode = $tag_type;
         }
      }
   }
   # don't set invalid structures
   if( $isUnSet ) {
      foreach( @values ) {
         # check compose
         unless( $self->_typeCheck($tag,0,$_) ) {
            # check failed
            $errstr .= "Check Failed";
            return 0;
         }
      }
   }
   # can't unset inherited if unset
   if( $attri == A_INHERIT and $isUnSet 
         and not exists $self->{'inherited'}->{$branch}->{$node}->{$tag} ) {
      $errstr = "Can't unset inherited $tag when not set at this node\n";
      return 0;
   }
   # can't unset tag if unset
   if( $attri != A_INHERIT and $isUnSet 
         and not exists $node->{$tag} ) {
      $errstr = "Can't unset non existant tag\n";
      return 0;
   }
   # If I got here then it is safe to do some damage

   # if inherit use other tree

   if( $attri == A_INHERIT ) {
      if( $isUnSet ) {
         delete $self->{'inherited'}->{$branch}->{$node}->{$tag};
      } else {
         #set
         $self->{'inherited'}->{$branch}->{$node}->{$tag} = [@values];
      }
   } elsif( $isUnSet ) {
      delete $node->{$tag};
   } else {
      $node->{$tag} = [@values];
   }

   return 1;
}
sub _getBranch {
   my $self = shift;
   return $self->{'parents'}->[@{$self->{'parents'}} - 1 ];
}
sub _getNode {
   my $self = shift;
   my $branch = $self->_getBranch();
   return $branch->[0]->[$self->{'node'}];
}
#TODO finish these and integrate them into the module
#        _typeRead replaces _typeParse
#           returns struct/parsed data
#           on failure return undef and set errstr
#        setProperty uses _typeCheck
#        _write will use _typeWrite
sub _typeRead {
   my $self = shift;
   my $tag = shift;
   my $isSecond = shift;
   my $text = shift;
   my $type = $self->_getTagValueType($tag);
   if( ref $type eq 'ARRAY' ) {
      $type = $type->[$isSecond ? 1 : 0];
   }
   _debug( "typeRead: ($tag, '$text')\n");
   #return $text unless $type;
   if($type == V_COLOR) {
      if( $text eq "B" ) {
         return C_BLACK;
      } elsif( $text eq "W" ) {
         return C_WHITE;
      } else {
         $errstr = "Invalid COLOR: '$text'";
         return undef;
      }
   } elsif( $type == V_DOUBLE ) {
      if( $text eq "1" ) {
         return DBL_NORM;
      } elsif( $text eq "2" ) {
         return DBL_EMPH;
      } else {
         $errstr = "Invalid DOUBLE: '$text'";
         return undef;
      }
   } elsif( $type == V_NUMBER) {
      if( $text =~ m/^[+-]?[0-9]+$/ ) {
         return $text;
      } else {
         $errstr = "Invalid NUMBER: '$text'";
         return undef;
      }
   } elsif( $type == V_REAL ) {
      if( $text =~ m/^[+-]?[0-9]+(\.[0-9]+)?$/ ) {
         return $text;
      } else {
         $errstr = "Invalid REAL: '$text'";
         return undef;
      }
   } elsif( $type == V_TEXT ) {
      return $text;
   } elsif( $type == V_SIMPLE_TEXT ) {
      #TODO do some final processing 
      #  compact all whitespace
      return $text;
   } elsif( $type == V_NONE ) {
      if( $text ) {
         croak "Invalid NONE: '$text'";
      } else {
         return undef;
      }
   # game specific
   } elsif( $type == V_POINT ) {
      #if sub then call it and pass $text in
      if($self->{'pointRead'}) {
         return $self->{'pointRead'}->($text);
      } 
   } elsif( $type == V_STONE ) {
      if($self->{'stoneSub'}) {
         return $self->{'stoneRead'}->($text);
      }
   } elsif( $type == V_MOVE ) {
      if($self->{'moveSub'}) {
         return $self->{'moveRead'}->($text);
      }
   } else {
      $errstr = "Invalid type: $type\n";
      return undef;
   }
   return $text;
}
# on V_TEXT and V_SIMPLE_TEXT auto escapes :, ], and \
# there should be no need to worry abour composed escaping
sub _typeCheck {
   my $self = shift;
   my $tag = shift;
   my $isSecond = shift;
   my $struct = shift;
   my $type = $self->_getTagValueType($tag);
   if( ref $type eq 'ARRAY' ) {
      $type = $type->[$isSecond ? 1 : 0];
   }
   _debug( "typeCheck: ($tag, '$struct')\n");
   if($type == V_COLOR) {
      if( $struct == C_BLACK or $struct == C_WHITE ) {
         return 1;
      } else {
         return 0;
      }
   } elsif( $type == V_DOUBLE ) {
      if( $struct == DBL_NORM or $struct == DBL_EMPH ) {
         return 1;
      } else {
         return 0;
      }
   } elsif( $type == V_NUMBER) {
      if( $struct =~ m/^[+-]?[0-9]+$/ ) {
         return 1;
      } else {
         return 0;
      }
   } elsif( $type == V_REAL ) {
      if( $struct =~ m/^[+-]?[0-9]+(\.[0-9]+)?$/ ) {
         return 1;
      } else {
         return 0;
      }
   } elsif( $type == V_TEXT ) {
      #TODO update
      return 1;
   } elsif( $type == V_SIMPLE_TEXT ) {
      #TODO update
      return 1;
   } elsif( $type == V_NONE ) {
      if( $struct ) {
         return 0;
      } else {
         return 1;
      }
   } elsif( $type == V_POINT ) {
      if($self->{'pointCheck'}) {
         return $self->{'pointCheck'}->($struct);
      }
   } elsif( $type == V_STONE ) {
      if($self->{'stoneCheck'}) {
         return $self->{'stoneCheck'}->($struct);
      }
   } elsif( $type == V_MOVE ) {
      if($self->{'moveCheck'}) {
         return $self->{'moveCheck'}->($struct);
      }
   } else {
      $errstr = "Invalid type: $type\n";
      return undef;
   }
   # maybe game specific stuff shouldn't be pass through
   return 1;
}
sub _typeWrite {
   my $self = shift;
   my $tag = shift;
   my $isSecond = shift;
   my $struct = shift;
   my $type = $self->_getTagValueType($tag);
   if( ref $type eq 'ARRAY' ) {
      $type = $type->[$isSecond ? 1 : 0];
   }
   my $text;
   _debug( "typeWrite: ($tag, '$struct')\n");
   if($type == V_COLOR) {
      if( $struct == C_BLACK ) {
         return "B";
      } elsif( $struct == C_WHITE ) {
         return "W";
      } else {
         $errstr = "typeRead: value '$struct'\n";
         return undef;
      }
   } elsif( $type == V_DOUBLE ) {
      if( $struct == DBL_NORM ) {
         return "1";
      } elsif( $struct == DBL_EMPH ) {
         return "2";
      } else {
         $errstr = "typeRead: Value '$struct'\n";
         return undef;
      }
   } elsif( $type == V_NUMBER) {
      return sprintf( "%d", $struct);
   } elsif( $type == V_REAL ) {
      return sprintf( "%f", $struct);
   } elsif( $type == V_TEXT ) {
      $struct =~ s/:/\\:/sg;
      $struct =~ s/]/\\]/sg;
      $struct =~ s/\\/\\\\/sg;
      return $struct;
   } elsif( $type == V_SIMPLE_TEXT ) {
      $struct =~ s/:/\\:/sg;
      $struct =~ s/]/\\]/sg;
      $struct =~ s/\\/\\\\/sg;
      return $struct;
   } elsif( $type == V_NONE ) {
      return "";
   } elsif( $type == V_POINT ) {
      if($self->{'pointWrite'}) {
         return $self->{'pointWrite'}->($struct);
      }
   } elsif( $type == V_STONE ) {
      if($self->{'stoneWrite'}) {
         return $self->{'stoneWrite'}->($struct);
      }
   } elsif( $type == V_MOVE ) {
      if($self->{'moveWrite'}) {
         return $self->{'moveWrite'}->($struct);
      }
   } else {
      $errstr = "Invalid type: $type\n";
      return undef;
   }
   return $struct;
}


sub _debug {
   print @_ if $DEBUG;
}
sub _getTagFlags {
   my $self = shift;
   my $tag = shift;
   if( exists $ff4_properties{$tag} ) {
      return 0 unless exists $ff4_properties{$tag}->{'value_flags'};
      return $ff4_properties{$tag}->{'value_flags'};
   } elsif( exists $self->{'tags'}->{$tag} ) {
      return 0 unless exists $self->{'tags'}->{$tag}->{'value_flags'};
      return $self->{'tags'}->{$tag}->{'value_flags'};
   } else {
      carp "Tag '$tag' Not Found\n";
      return (VF_EMPTY | VF_LIST); # allow to be empty or list
   }
}
sub _getTagType {
   my $self = shift;
   my $tag = shift;
   if( exists $ff4_properties{$tag} ) {
      return T_NONE unless exists $ff4_properties{$tag}->{'type'};
      return $ff4_properties{$tag}->{'type'};
   } elsif( exists $self->{'tags'}->{$tag} ) {
      return T_NONE unless exists $self->{'tags'}->{$tag}->{'type'};
      return $self->{'tags'}->{$tag}->{'type'};
   } else {
      return T_NONE; # allow to be anywhere
   }
}
sub _getTagAttribute {
   my $self = shift;
   my $tag = shift;
   if( exists $ff4_properties{$tag} ) {
      return A_NONE unless exists $ff4_properties{$tag}->{'attrib'};
      return $ff4_properties{$tag}->{'attrib'};
   } elsif( exists $self->{'tags'}->{$tag} ) {
      return A_NONE unless exists $self->{'tags'}->{$tag}->{'attrib'};
      return $self->{'tags'}->{$tag}->{'attrib'};
   } else {
      return A_NONE; # don't set inherit
   }
}
sub _getTagValueType {
   my $self = shift;
   my $tag = shift;
   if( exists $ff4_properties{$tag} ) {
      return V_TEXT unless exists $ff4_properties{$tag}->{'value'};
      return $ff4_properties{$tag}->{'value'};
   } elsif( exists $self->{'tags'}->{$tag} ) {
      return V_TEXT unless exists $self->{'tags'}->{$tag}->{'value'};
      return $self->{'tags'}->{$tag}->{'value'};
   } else {
      return V_TEXT; # allows and preserves any string
   }
}
sub _maybeComposed {
   my $self = shift;
   my $prop = shift;
   if( ref $self->_getTagValueType($prop) eq 'ARRAY'
         or $self->_getTagFlags($prop) & VF_OPT_COMPOSE ) {
      return 1;
   } else {
      return 0;
   }
}
sub _isSpaceRemovable {
   my $self = shift;
   my $prop = shift;
   my $part = shift;
   my $type = _getTagType($prop);
   if( $self->_maybeComposed($prop) ) {
      if( ref $type eq 'ARRAY' ) {
         if( $type->[$part] == V_SIMPLE_TEXT ) {
            return 1;
         }
      }
   } elsif( $type == V_SIMPLE_TEXT ) {
      return 1;
   }
   return 0;
}


# property is added at start of new tag, variation, or end of variation
sub _read {
   my $self = shift;
   my $text = shift;
   # Parse state
   my $lastChar = '';
   my $propertyName = '';
   my( @propertyValue ); # for current value 
   my $propI = 0;
   my $lastName = '';
   my( @values ) = (); # composed entries are array refs
   # Parse flags
   my $inValue = 0;
   my $isEscape = 0;
   my $isFinal = 0;
   my $isStart = 0;
   my $isFirst = 0;
   my $inTree = 0;
   _debug( "==SGF==\n\n$text\n==SGF==\n");
   # each gametree is a [\@sequence,\@gametress]
   for( my $i = 0; $i < length $text;$i++) {
      # ( start the game tree
      # ) end the game tree
      # ; start new node
      # [ start prop-value
      # ] end prop-value
      # a-Z not in [] are labels
      my $char = substr($text,$i,1);
      if( $inValue ) {
         if( $isEscape ) {
            if( $char eq '\n' ) {
               $char = "";
            }
            $propertyValue[$propI] .= $char;
            $isEscape = 0;
         } elsif( $char eq '\\' ) {
            $isEscape = 1;
         } elsif( $char eq ':' and $self->_maybeComposed($propertyName)) {
            if($propI >= 1 ) {
               $errstr =  "Too Many Compose components in value: FAILED";
               return undef;
            }
            $propI++;
            $propertyValue[$propI] = ""; # should be redundent
         } elsif( $char =~ /\s/ and $lastChar =~ /\s/
               and $self->_isSpaceRemovable($propertyName) ) {
            # don't add anything
         } elsif( $char =~ /\s/ ) {
            $propertyValue[$propI] .= " ";
         } elsif( $char eq ']' ) {
            # error if not invalue
            unless( $inValue ) {
               croak "Mismatched ']' : FAILED";
            }
            _debug( "Adding Property: '$propertyName' => '$propertyValue[$propI]'\n");
   
            # note empty tag will be pushed on as an empty string
            # _typeread before adding to values
            for( my $i = 0; $i < @propertyValue; $i++) {
               $propertyValue[$i] = $self->_typeRead( $propertyName, $i, $propertyValue[$i]);
            }
            push @values, $propI > 0 ? [@propertyValue] : $propertyValue[0];
   
            $lastName = $propertyName;
            $propertyName = '';
            @propertyValue = ();
            $propI = 0;
            $inValue = 0;
         } else {
            $propertyValue[$propI] .= $char;
         }

      # outside of a value 
      } elsif( $char eq '(' ) {
         if( @values ) {
            return undef if not $self->setProperty($lastName, @values); 
            @values = ();
         }
         if($inTree) {
            _debug( "Starting GameTree\n");
            if( not $self->addVariation ) {
               return undef;
            }
         } else {
            _debug "Adding GameTree to Collection\n";
            $inTree = 1;
            if( not $self->addGame ) {
               return undef;
            }
         }
         $isStart = 1;
      } elsif( $char eq ')' ) {
         if( @values ) {
            return undef if not $self->setProperty($lastName, @values); 
            @values = ();
         }
         if( not $self->gotoParent ) {
            $inTree = 0;
         }
      } elsif( $char eq ';' ) {
         _debug("Adding Node\n");
         if( @values ) {
            return undef if not $self->setProperty($lastName, @values); 
            @values = ();
         }
         if( not $inTree ) {
            $errstr =  "Attempted to start node outside of GameTree: Failed";
            return undef;
         }
         if( $isStart ) {
            $isStart = 0;
         } elsif( not $self->addNode ) {
            return undef;
         }
      } elsif( $char eq '[' ) {
         $inValue = 1;
         $isFinal = 0;
         # handle tag types here
         # T_ROOT only when $current = $node
         $isFirst = 1;
         unless( $propertyName ) {
            $isFirst = 0;
            $propertyName = $lastName;
         }
      } elsif( $char =~ /\s/ ) {
         # catch all whitespace
         # to make sure it doesn't come in the middle of a
         # property name
         $isFinal = 1 if $propertyName;
      } elsif( $char =~ /[a-zA-Z]/ ) {
         # error if final
         if( @values ) {
            return undef if not $self->setProperty($lastName, @values); 
            @values = ();
         }
         if( $isFinal ) {
            croak "Tag must have no spaces and must have a value: FAILED";
         }
         $propertyName .= $char;
         $lastName = "";
      } else {
         croak "Unknown condition with char '$char': FAILED";
         # error
      }
      $lastChar = $char;
   }
   return 1;
}
1;

__END__

=head1 CONSTANTS

=head2 Type

These are the defined property types. They tell the engine where the tag is allowed
to be. 

=over

=item T_MOVE

This is used for properties discribing a move. T_MOVE and T_SETUP tags may not
be present in the same node.

=item T_SETUP

These properties are used for setting up a position on the board. Such as
placing stones on the board.

=item T_ROOT

These properties must be in the root node. This is the root of the collection,
not the root of a variation tree.

=item T_GAME_INFO

These are used for discribing the game. They should be on the earliest node,
that the game is evident. For example if the SGF file is a fuseki, the Game_info
should be when the game becomes unique in the collection.

=item T_NONE

There is no placement restrictions placed on tags of this type.

=back

These can be in any node. There is no resrictions placed on these nodes.

=head2 Value Type

These discribe the types of data contained in a tag.

=over

=item V_NONE

These properties have no tag content.

=item V_NUMBER

This is a number which satifisies the regex:  C<[+-]?[0-9]+>

=item V_REAL

This is a number which satifisies the regex: C<[+-]?[0-9]+(\.[0-9]+)?>

=item V_DOUBLE

This is used for emphasies. For example GB move the good for black
property. GB[1] would mean "Good for Black" GB[2] would mean "Very Good
for Black."

=over

=item DBL_NORM

Used for normal emphasis. When 1 is passed into a V_DOUBLE.

=item DBL_EMPH

Used for emphasis. When 2 is passed into a V_DOUBLE.

=back

=item V_COLOR

This is used to specify a color, such as which color starts.

=over

=item C_BLACK

Used when B is passed into a V_COLOR tag.

=item C_WHITE

Used when W is passed into a V_COLOR tag.

=back

=item V_TEXT

Can take pretty much any text.

=item V_SIMPLE_TEXT

Same as V_TEXT except all spaces are reduced down to a single space.

=item V_POINT

This is used to specify a point on the board. Used for marking positions.
This is a Game Specific property type and will be handled as V_TEXT unless
a parsing callback is specified.

=item V_STONE

This is used to specify a stone or placement of a stone on the board on the
board. Used for stone placement. This is a Game Specific property type and
will be handled as V_TEXT unless a parsing callback is specified.

=item V_MOVE

This is used to specify a move on the board. Used making moves on the board.
This is a Game Specific property type and will be handled as V_TEXT unless
a parsing callback is specified.

=back

=head2 Flags

These are various flags that can be given to a property tag. Since these are
bit flags, in order to set more then one flag use the bitwise C<|> operator.
For example to set both the C<VF_EMPTY> and C<VF_LIST> flag use 
C<VF_EMPTY | VF_LIST>.

=over

=item VF_EMPTY

This also's the property to the tag to be empty. For Example MA uses this
flag:

  MA[]

  or

  MA[ff][gg]

=item VF_LIST

This allows you to list properties together. The second example above
demstrates this behavior.  Used in conjunction with VF_EMPTY allows you
to have a empty list, otherwise it must have at least one property
given.

=item VF_OPT_COMPOSE

This tag allows a property to be composed with itself. For example in the
specification any List of Points can be used as a List of Point composed with
point, in order to specify a rectangular region of points. As an Example:

  MA[aa][ab][ba][bb]

  is equavalent to:

  MA[aa:bb]

=back

=head2 Attribute

=over

=item A_NONE

Used to specify no Attribute is set.

=item A_INHERIT

Currently the only Attribute defined in the specs. This property value will
be passed down to all subsequient nodes, untill a new value is set.

=back

=head1 ASSUMPTIONS

=over

=item All Inherited properties are T_NONE

This holds true for standard FF4 and I believe it would cause conflict
if it was not true.

=back

=head1 TODO

=over

=item Write Test Code

=back

=head1 ALSO SEE

L<http://www.red-bean.com/sgf>

L<Games::Goban>

L<Games::Go::SGF>

=head1 AUTHOR

David Whitcomb, C<< <whitcode at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-sgf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-SGF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.
