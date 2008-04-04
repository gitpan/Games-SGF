package Games::SGF;

use strict;
use warnings;
use Carp qw(carp croak confess);
use enum qw( 
         :C_=1 BLACK WHITE
         :DBL_=1 NORM EMPH
         :V_=1 NONE NUMBER REAL DOUBLE COLOR SIMPLE_TEXT TEXT POINT MOVE STONE
         BITMASK:VF_=1 EMPTY LIST OPT_COMPOSE
         :T_=1 MOVE SETUP ROOT GAME_INFO NONE
         :A_=1 NONE INHERIT
         );

=head1 NAME

Games::SGF - A general SGF parser

=head1 VERSION

Version 0.05

=cut


our $VERSION = 0.05;
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
   'PL' => { 'type' => T_SETUP, 'value' => V_COLOR },

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
   'AP' => { 'type' => T_ROOT, 'value' => [V_SIMPLE_TEXT, V_SIMPLE_TEXT] },
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


SGF Format

User Format

Internal Format

Point, Stone, Move Converts User Format to Internal Format

typeRead, typeWrite convert SGF to Internal

typeCheck checks the internal structure(needs to handle blessedness)

Attributes specify other behavior.

Also see: L<http://www.red-bean.com/sgf>

=head1 METHODS

=head2 new

  new Games::SGF(%options);

Creates a SGF object.

Options that new will look at.

=over

=item debug

  new Games::SGF(debug => 1);

This will tell the SGF parser to spit out text as it parses.

=back

=cut

sub new {
   my $inv = shift;
   my $class = ref( $inv) || $inv;
   my( %opts ) = @_;
   my $self = {};
   # stores added tags
   $self->{'tags'} = {};
   # stores stone, point, move handling subroutines
   $self->{'game'} = undef; 
   $self->{'collection'} = undef; 
   $self->{'parents'} = undef; 
   $self->{'node'} = undef;
   $self->{'debug'} = $opts{'debug'} || 0; 
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
      #$self->{'errstr'} = "No Games read in by readText\n";
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
      $self->err( "Failed to open File '$filename': $!\n" );
      return undef;
   }
   if(read( $fh, $text, -s $filename) == 0 ) {
      $self->err( "Failed to read File '$filename': $!\n");
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
            # _type* take care of composed values now
            # add value
            my $val = $self->_tagWrite($tag,0,$val);
            return undef if not defined $val;
            $text .= $val;
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
      my( %inherit );
      # find the tags
      foreach my $tag ( keys %{$self->{'inherited'}}) {
         if( exists $self->{'inherited'}->{$tag}->{$branch}->{$i} ) {
            $inherit{$tag} = $self->{'inherited'}->{$tag}->{$branch}->{$i};
         }
      }
      $text .= $self->_write_tags(\%inherit);
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
      $self->err( "Failed to open File '$filename': $!\n");
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
      $self->err( "addTag( $tagname ); FAILED : $tagname already exists\n");
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
   if( exists( $self->{'pointRead'} )) {
      $self->err( "Point Read subroutine already exists\n");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'pointRead'} = $coderef;
   } else {
      $self->err( "Point Read subroutine was not a subroutine reference\n");
      return 0;
   }
   return 1;
}

=head2 setMoveRead

=cut

sub setMoveRead {
   my $self = shift;
   my $coderef = shift;
   if( exists( $self->{'moveRead'} )) {
      $self->err( "Move Read subroutine already exists\n");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'moveRead'} = $coderef;
   } else {
      $self->err( "Move Read subroutine was not a subroutine reference\n");
      return 0;
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

If the value is an empty string and VF_RMPTY is set then the call back will
not be called but return an empty string.

=cut

sub setStoneRead {
   my $self = shift;
   my $coderef = shift;
   if( exists( $self->{'stoneRead'} )) {
      $self->err( "Stone Read subroutine already exists\n");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'stoneRead'} = $coderef;
   } else {
      $self->err( "Stone Read subroutine was not a subroutine reference\n");
      return 0;
   }
   return 1;
}


=head2 setPointCheck

=cut


sub setPointCheck {
   my $self = shift;
   my $coderef = shift;
   if( exists( $self->{'pointCheck'} )) {
      $self->err( "Point Check subroutine already exists\n");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'pointCheck'} = $coderef;
   } else {
      $self->err( "Point Check subroutine was not a subroutine reference\n");
      return 0;
   }
   return 1;
}

=head2 setMoveCheck

=cut

sub setMoveCheck {
   my $self = shift;
   my $coderef = shift;
   if( exists( $self->{'moveCheck'} )) {
      $self->err( "Move Check subroutine already exists\n");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'moveCheck'} = $coderef;
   } else {
      $self->err( "Move Check subroutine was not a subroutine reference\n");
      return 0;
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

If the value is an empty string it will be passed to the check callback
only if VF_EMPTY is not set.

=cut

sub setStoneCheck {
   my $self = shift;
   my $coderef = shift;
   if( exists( $self->{'stoneCheck'} )) {
      $self->err( "Stone Check subroutine already exists\n");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'stoneCheck'} = $coderef;
   } else {
      $self->err( "Stone Check subroutine was not a subroutine reference\n");
      return 0;
   }
   return 1;
}

=head2 setPointWrite

=cut


sub setPointWrite {
   my $self = shift;
   my $coderef = shift;
   if( exists( $self->{'pointWrite'} )) {
      $self->err( "Point Write subroutine already exists\n");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'pointWrite'} = $coderef;
   } else {
      $self->err( "Point Write subroutine was not a subroutine reference\n");
      return 0;
   }
   return 1;
}

=head2 setMoveWrite

=cut

sub setMoveWrite {
   my $self = shift;
   my $coderef = shift;
   if( exists( $self->{'moveWrite'} )) {
      $self->err( "Move Write subroutine already exists\n");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'moveWrite'} = $coderef;
   } else {
      $self->err( "Move Write subroutine was not a subroutine reference\n");
      return 0;
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

If the tag value is an empty string it will not be sent to the write callback, but immedeitely be returned as an empty string.

=cut

sub setStoneWrite {
   my $self = shift;
   my $coderef = shift;
   if( exists( $self->{'stoneWrite'} )) {
      $self->err( "Stone Write subroutine already exists\n");
      return 0;
   }
   if( ref $coderef eq 'CODE' ) {
      $self->{'stoneWrite'} = $coderef;
   } else {
      $self->err( "Stone Write subroutine was not a subroutine reference\n");
      return 0;
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
      $self->{'parents'} = [ $self->{'collection'}->[$self->{'game'}] ];
      $self->{'node'} = 0;
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
      $self->{'parents'} = [ $self->{'collection'}->[$self->{'game'}] ];
      $self->{'node'} = 0;
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

   if( $self->{'node'} > @{$branch->[0]} ) {
      $self->err("Last Node in branch sequence " . $self->{'node'}
         . " out of " . scalar @{$branch->[0]});
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
      $self->err("Can't goto variation greater then number on branch");
      return 0;
   } else {
      push @{$self->{'parents'}}, $branch->[1]->[$n];
      $self->{'node'} = 0;
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
      $self->err("Can't add Node since there exists a variation\n");
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
   my $n = $self->{'node'};
   my $new_branch = [[],[]];
   my $branch = $self->_getBranch();
   if( $n > 0 and $n < @{$branch->[0]} ) {
      $new_branch->[0] = [splice @{$branch->[0]}, $n];
      $new_branch->[1] = $branch->[1];
      $branch->[1] = [$new_branch];
      $self->{'node'} = $n - 1;
      return 1;
   } else {
      return 0;
   }
}

=head2 flatten

  $sgf->flatten;

If the current branch has only one variation then moves nodes and variations
from that one variation into current branch, and removing the old branch.

=cut

sub flatten {
   my $self = shift;
   if( $self->variations == 1 ) {
      my $branch = $self->_getBranch();
      my $tbd = $branch->[1]->[0];

      # moves stuff
      push @{$branch->[0]}, @{$tbd->[0]};
      $branch->[1] =  $tbd->[1];
      return 1;
   } else {
      $self->err( "Can not flatten branch with more then one Variation" );
      return 0;
   }
}


=head2 property

  my( @tags ) = $sgf->property;
  my $array_ref = $sgf->property( $value );
  my $didSave = $sgf->property( $value , @values );

This is used to read and set properties on the current node. Will prevent T_MOVE
and T_SETUP types from mixing. Will prevent writing T_ROOT tags to any location
other then the root node. Will Lists from being stored in non list tags. Will
prevent invalid structures from being stored.

If no options are given it will return all the tags set on this node. Inherited
tags will only be returned if they were set on this node.

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
   if( not defined $tag ) {
      my @tags;
      my $branch = $self->_getBranch;
      my $node = $self->_getNode;
      @tags = keys %$node;
      foreach my $t ( $self->{'inherited'} ) {
         if( exists $self->{'inherited'}->{$t}->{$branch}->{$self->{'node'}} ) {
            push @tags, $t;
         }
      }
      return @tags;

   } elsif( @values == 0 ) {
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
      if( not exists $self->{'inherited'}->{$tag} ) {
         $self->err( "Inherited Tag($tag) not set anywhere" );
         return 0;
      }
      foreach(@{$self->{'parents'}}) {
         if( exists $self->{'inherited'}->{$tag}->{$_} ) {
            $closest = $_;
         }
      }
      if( not defined $closest ) {
         # none found
         $self->err( "Inherited tag($tag) not found");
         return 0;
      } elsif( $closest == $branch )  {
         # find greatest node less then or equal to $self->{'node'}
         my $n;
         for( $n = $self->{'node'}; $n >= 0; $n--) {
            if( exists $self->{'inherited'}->{$tag}->{$closest}->{$n} ) {
               return $self->{'inherited'}->{$tag}->{$closest}->{$n};
            }
         }
         $self->err( "inherited $tag not found in current branch");
         return 0;
      } else {
         # find greastest node
         my $max = -1;
         foreach( keys %{$self->{'inherited'}->{$tag}->{$closest}} ) {
            $max = $_ if $_ > $max;
         }
         if( $max >= 0 ) {
            return $self->{'inherited'}->{$tag}->{$closest}->{$max};
         } else {
            $self->err( "inherited $tag not found");
            return 0;
         }
      }
   } else {
      if( exists $node->{$tag} ) {
         return $node->{$tag};
      } else {
         # non existent $tag
         $self->err( "non existent $tag");
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

#TODO fix inherit
#        structure should be {Tag}{Branch}{Node}
#     so that you 

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
   my $isComposable = $self->_maybeComposed($tag);
   # reasons to not set the property
   # set list values only if VF_LIST
   if( @values > 1 and not $flags & VF_LIST ) {
      $self->err( "Can't set list for non VF_LIST: ($tag, $flags : " . 
         join( ":", VF_EMPTY, VF_LIST, VF_OPT_COMPOSE) . ")\n");
      return 0;
   }
   # can set T_ROOT if you are at root
   if( $ttype == T_ROOT and (@{$self->{'parents'}} != 1 or $self->{'node'} != 0) ) {
      $self->err( "Can't set T_ROOT($tag) when not at root( Parents: "
                  . scalar(@{$self->{'parents'}}) . 
                  " Node: " . $self->{'node'} . "\n");
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
            $self->err("Can't mix T_SETUP and T_MOVES\n");
            return 0;
         } elsif( $tnode == undef
               and ($tag_type == T_MOVE or $tag_type == T_SETUP) ) {
            $tnode = $tag_type;
         }
      }
   }
   # don't set invalid structures
   if(not  $isUnSet ) {
      foreach( @values ) {
         # check compose
         if( $self->isComposed($_) ) {
            unless( $isComposable ) {
               $self->err( "Found Composed value when $tag does not allow it");
               return 0;
            }
            unless($self->_tagCheck($tag,0, $_)){
               $self->err( "Check Failed");
               return 0;
            }
         } else {
            unless( $self->_tagCheck($tag,0,$_) ) {
               # check failed
               $self->err( "Check Failed");
               return 0;
            }
         }
      }
   }
   # can't unset inherited if unset
   if( $attri == A_INHERIT and $isUnSet 
         and not exists $self->{'inherited'}->{$tag}->{$branch}->{$self->{'node'}} ) {
      $self->err( "Can't unset inherited $tag when not set at this node\n");
      return 0;
   }
   # can't unset tag if unset
   if( $attri != A_INHERIT and $isUnSet 
         and not exists $node->{$tag} ) {
      $self->err("Can't unset non existant tag\n");
      return 0;
   }
   # If I got here then it is safe to do some damage

   # if inherit use other tree

   if( $attri == A_INHERIT ) {
      if( $isUnSet ) {
         delete $self->{'inherited'}->{$tag}->{$branch}->{$self->{'node'}};
      } else {
         #set
         $self->{'inherited'}->{$tag}->{$branch}->{$self->{'node'}} = [@values];
      }
   } elsif( $isUnSet ) {
      delete $node->{$tag};
   } else {
      $node->{$tag} = [@values];
   }

   return 1;
}

=head2 compose

  ($pt1, $pt2) = $sgf->compose($compose);
  $compose = $sgf->compose($pt1,$pt2);

Used for creating and breaking apart composed values. If you will be setting
or fetching a composed value you will be needing this function to breack it
apart.

=cut

sub compose {
   my $self = shift;
   my $cop1 = shift;
   if( $self->isComposed($cop1) ) {
      return @$cop1;
   } else {
      my $cop2 = shift;
      return bless [$cop1,$cop2], 'Games::SGF::compose';
   }
}

=head2 isComposed

  if( $sgf->isComposed($compose) ) {
     ($val1, $val2) = $sgf->compose($compose);
  }


This returns true if the value passed in is a composed value, otherwise
false.

=cut

sub isComposed {
   my $self = shift;
   my $val = shift;
   return ref $val eq 'Games::SGF::compose';
}

=head2 isPoint

=head2 isStone

=head2 isMove

  $self->isPoint($val);

Returns true if $val is a point, move or stone.

The determination for this is if it is blessing class matches
C<m/^Games::SGF::.*type$/> where type is point, stone, or move.
So as long as read,write,check methods work with it there is no
need for these methods to be overwritten.

=cut

#TODO match /^Games::SGF::.*move$/

sub isPoint {
   my $self = shift;
   my $val = ref shift;
   return $val =~ m/^Games::SGF::.*point$/;
}
sub isStone {
   my $self = shift;
   my $val = ref shift;
   return $val =~ m/^Games::SGF::.*stone$/;
}
sub isMove {
   my $self = shift;
   my $val = ref shift;
   return $val =~ m/^Games::SGF::.*move$/;
}

=head2 point

=head2 stone

=head2 move

  $struct = $sgf->move(@cord);
  @cord = $sgf->move($struct);

If a point, stone, or move is passed in, it will be broken into it's parts
and returned. If the parts are passed in it will construct the internal
structure which the parser uses.

Will treat the outside format the same as the SGF value format. Thus will use 
the read and write callbacks for point,stone, and move.

If the SGF representation is not what you desire then override these.

=cut

#TODO remove blessed status before passing to _typeWrite

sub point {
   my $self = shift;
   if( $self->isPoint($_[0]) ) {
      return @{$self->_typeWrite(V_POINT,@$_[0])};
   } else {
      return $self->_typeRead(V_POINT, $_[0]);
   }
}
sub stone {
   my $self = shift;
   if( $self->isStone($_[0]) ) {
      return @{$self->_typeWrite(V_STONE,@$_[0])};
   } else {
      return $self->_typeRead(V_STONE, $_[0]);
   }
}
sub move {
   my $self = shift;
   if( $self->isMove($_[0]) ) {
      return @{$self->_typeWrite(V_MOVE,@$_[0])};
   } else {
      return $self->_typeRead(V_MOVE, $_[0]);
   }
}

=head2 err

  if( $sgf->err ) {
     print $sgf->err;
     return 0;
  }

  # This is for extending modules and internal use
  $sgf->err( "Will set error message");

Sets and fetchs the current error message.

=cut

sub err {
   my $self = shift;
   my $string = shift;
   if( defined $string ) {
      $self->{'errstr'} = $string;
   } else {
      return $self->{'errstr'};
   }
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

# adjust _typeRead so that if it gets a compose
# it will break it into two calls to itself
#
# same with _typeCheck
#
# have write automaticly put the ':' in place

# Read should not be passed a compose but a list of values, then it
# will compose them

sub _tagRead {
   my $self = shift;
   my $tag = shift;
   my $isSecond = shift;
   my( @values ) = @_;

   # composed
   if( @values > 1 ) {
      $values[0] = $self->_tagRead($tag,0,$values[0]);
      $values[1] = $self->_tagRead($tag,1,$values[1]);
      return $self->compose(@values);
   }
   my $type = $self->_getTagValueType($tag);
   if( ref $type eq 'ARRAY' ) {
      $type = $type->[$isSecond ? 1 : 0];
   }

   # if empty just return empty
   if( $values[0] eq "" ) {
      if( $type == 1 ) {
         return "";
      } elsif( $self->_getTagFlags($tag) & VF_EMPTY ) {
         return "";
      } elsif( not($type == V_POINT or $type == V_MOVE or $type == V_STONE ) ) {
         $self->err(" Empty tag found where one should not be ");
         return 0;
      }
   }
   $self->_debug( "tagRead($tag, $isSecond, '".$values[0]."')\n");
   return $self->_typeRead($type,$values[0]);

}

sub _typeRead {
   my $self = shift;
   my $type = shift;
   my $text = shift;

   $self->_debug("typeRead($type,$text)\n");
   #return $text unless $type;
   if($type == V_COLOR) {
      if( $text eq "B" ) {
         return C_BLACK;
      } elsif( $text eq "W" ) {
         return C_WHITE;
      } else {
         $self->err("Invalid COLOR: '$text'");
         return undef;
      }
   } elsif( $type == V_DOUBLE ) {
      if( $text eq "1" ) {
         return DBL_NORM;
      } elsif( $text eq "2" ) {
         return DBL_EMPH;
      } else {
         $self->err( "Invalid DOUBLE: '$text'");
         return undef;
      }
   } elsif( $type == V_NUMBER) {
      if( $text =~ m/^[+-]?[0-9]+$/ ) {
         return $text;
      } else {
         $self->err( "Invalid NUMBER: '$text'");
         return undef;
      }
   } elsif( $type == V_REAL ) {
      if( $text =~ m/^[+-]?[0-9]+(\.[0-9]+)?$/ ) {
         return $text;
      } else {
         $self->err( "Invalid REAL: '$text'");
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
         return "";
      }
   # game specific
   } elsif( $type == V_POINT ) {
      #if sub then call it and pass $text in
      if($self->{'pointRead'}) {
         return $self->{'pointRead'}->($text);
      } else {
        return bless [$text], 'Games::SGF::Point';
      }
   } elsif( $type == V_STONE ) {
      if($self->{'stoneRead'}) {
         return $self->{'stoneRead'}->($text);
      } else {
        return bless [$text], 'Games::SGF::stone';
      }
   } elsif( $type == V_MOVE ) {
      if($self->{'moveRead'}) {
         return $self->{'moveRead'}->($text);
      } else {
         return bless [$text], 'Games::SGF::move';
      }
   } else {
      $self->err( "Invalid type: $type\n");
      return undef;
   }
   return $text;
}
# on V_TEXT and V_SIMPLE_TEXT auto escapes :, ], and \
# there should be no need to worry abour composed escaping
#
# adjust to check composed values?
sub _tagCheck {
   my $self = shift;
   my $tag = shift;
   my $isSecond = shift;
   my $struct = shift;

   # composed
   if( $self->isComposed($struct) ) {
      my( @val ) = $self->compose($struct);
      $val[0] = $self->_tagCheck($tag,0,$val[0]);
      $val[1] = $self->_tagCheck($tag,1,$val[1]);
      return $val[0] && $val[1];
   }

   my $type = $self->_getTagValueType($tag);
   if( ref $type eq 'ARRAY' ) {
      $type = $type->[$isSecond ? 1 : 0];
   }
   # if empty and VF_EMPTY return true unless point, move, or stone
   if( $struct eq "" ) {
      if( $type == V_NONE ) {
         return 1;
      } elsif( $self->_getTagFlags($tag) & VF_EMPTY ) {
         # return empty if not move stone or point
         return 1;
      } elsif(not( $type == V_POINT or $type == V_MOVE or $type == V_STONE ) ) {
         $self->err( "Check failed with invalid string($tag, $struct)");
         return 0;
      }
   }
   $self->_debug( "tagCheck($tag, '$struct')\n");
   return $self->_typeCheck($type,$struct);
}

sub _typeCheck {
   my $self = shift;
   my $type = shift;
   my $struct = shift;

   $self->_debug("typeCheck($type,$struct)\n");

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
      $self->err( "Invalid type: $type\n" );
      return undef;
   }
   # maybe game specific stuff shouldn't be pass through
   return 1;
}
sub _tagWrite {
   my $self = shift;
   my $tag = shift;
   my $isSecond = shift;
   my $struct = shift;

   # composed
   if( $self->isComposed($struct) ) {
      my( @val ) = $self->compose($struct);
      $val[0] = $self->_tagWrite($tag,0,$val[0]);
      $val[1] = $self->_tagWrite($tag,1,$val[1]);
      return join ':', @val;
   }

   my $type = $self->_getTagValueType($tag);
   if( ref $type eq 'ARRAY' ) {
      $type = $type->[$isSecond ? 1 : 0];
   }
   # if empty just return empty
   if( $struct eq "" and ($self->_getTagFlags($tag) & VF_EMPTY 
            or $type == V_NONE) ) {
      # if still empty it is ment to be empty
      return "";
   }
   $self->_debug( "tagWrite($tag, $isSecond, '$struct')\n");
   return $self->_typeWrite($type,$struct);
} 
sub _typeWrite {
   my $self = shift;
   my $type = shift;
   my $struct = shift;
   my $text;
   $self->_debug("typeWrite($type,'$struct')\n");
   if($type == V_COLOR) {
      if( $struct == C_BLACK ) {
         return "B";
      } elsif( $struct == C_WHITE ) {
         return "W";
      } else {
         $self->err( "typeWrite: value '$struct'\n" );
         return undef;
      }
   } elsif( $type == V_DOUBLE ) {
      if( $struct == DBL_NORM ) {
         return "1";
      } elsif( $struct == DBL_EMPH ) {
         return "2";
      } else {
         $self->err( "typeWrite: Value '$struct'\n");
         return undef;
      }
   } elsif( $type == V_NUMBER) {
      return sprintf( "%d", $struct);
   } elsif( $type == V_REAL ) {
      return sprintf( "%f", $struct);
   } elsif( $type == V_TEXT ) {
      $struct =~ s/([:\]\\])/\\$1/sg;
      return $struct;
   } elsif( $type == V_SIMPLE_TEXT ) {
      $struct =~ s/([:\]\\])/\\$1/sg;
      return $struct;
   } elsif( $type == V_NONE ) {
      return "";
   } elsif( $type == V_POINT ) {
      if($self->{'pointWrite'}) {
         return $self->{'pointWrite'}->($struct);
      } else {
         return $struct->[0];
      }
   } elsif( $type == V_STONE ) {
      if($self->{'stoneWrite'}) {
         return $self->{'stoneWrite'}->($struct);
      } else {
         return $struct->[0];
      }
   } elsif( $type == V_MOVE ) {
      if($self->{'moveWrite'}) {
         return $self->{'moveWrite'}->($struct);
      } else {
         return $struct->[0];
      }
   } else {
      $self->err( "Invalid type: $type\n" );
      return undef;
   }
   return $struct;
}


sub _debug {
   my $self = shift;
   print @_ if $self->{'debug'};
}
sub _getTagFlags {
   my $self = shift;
   my $tag = shift;
   if( exists( $ff4_properties{$tag}) ) {
      if( $ff4_properties{$tag}->{'value_flags'} ) {
         return $ff4_properties{$tag}->{'value_flags'};
      } else {
         return 0;
      }
   } elsif( exists( $self->{'tags'}->{$tag}) ) {
      if( $self->{'tags'}->{$tag}->{'value_flags'} ) {
         return $self->{'tags'}->{$tag}->{'value_flags'};
      } else {
         return 0;
      }
   }
   #carp "Tag '$tag' Not Found\n";
   # default flags
   return (VF_EMPTY | VF_LIST); # allow to be empty or list
}
sub _getTagType {
   my $self = shift;
   my $tag = shift;
   if( exists( $ff4_properties{$tag}) ) {
      if( $ff4_properties{$tag}->{'type'} ) {
         return $ff4_properties{$tag}->{'type'};
      }
   } elsif( exists( $self->{'tags'}->{$tag}) ) {
      if( $self->{'tags'}->{$tag}->{'type'} ) {
         return $self->{'tags'}->{$tag}->{'type'};
      }
   }
   # default Type
   return T_NONE; # allow to be anywhere
}
sub _getTagAttribute {
   my $self = shift;
   my $tag = shift;
   if( exists( $ff4_properties{$tag}) ) {
      if( $ff4_properties{$tag}->{'attrib'} ) {
         return $ff4_properties{$tag}->{'attrib'};
      }
   } elsif( exists($self->{'tags'}->{$tag}) ) {
      if( $self->{'tags'}->{$tag}->{'attrib'} ) {
         return $self->{'tags'}->{$tag}->{'attrib'};
      }
   }
   return A_NONE; # don't set inherit
}
sub _getTagValueType {
   my $self = shift;
   my $tag = shift;
   if( exists( $ff4_properties{$tag}) ) {
      if( $ff4_properties{$tag}->{'value'} ) {
         return $ff4_properties{$tag}->{'value'};
      }
   } elsif( exists( $self->{'tags'}->{$tag}) ) {
      if( $self->{'tags'}->{$tag}->{'value'} ) {
         return $self->{'tags'}->{$tag}->{'value'};
      }
   }
   return V_TEXT; # allows and preserves any string
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
sub _isSimpleText {
   my $self = shift;
   my $prop = shift;
   my $part = shift;
   my $type = $self->_getTagValueType($prop);
   if( $self->_maybeComposed($prop) ) {
      if( ref $type eq 'ARRAY' ) {
         if( $type->[$part] == V_SIMPLE_TEXT ) {
            #carp "Return 1?";
            return 1;
         }
      } elsif( $type == V_SIMPLE_TEXT ) {
         #carp "Return 1?";
         return 1;
      }
   } elsif( $type == V_SIMPLE_TEXT ) {
      #carp "Return 1?";
      return 1;
   }
   return 0;
}
sub _isText {
   my $self = shift;
   my $prop = shift;
   my $part = shift;
   my $type = $self->_getTagValueType($prop);
   if( $self->_maybeComposed($prop) ) {
      if( ref $type eq 'ARRAY' ) {
         if( $type->[$part] == V_TEXT ) {
            #carp "Return 1?";
            return 1;
         }
      } elsif( $type == V_TEXT ) {
         #carp "Return 1?";
         return 1;
      }
   } elsif( $type == V_TEXT ) {
      #carp "Return 1?";
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
   $self->_debug( "==SGF==\n\n$text\n==SGF==\n");
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
         if( $char eq ']' and not $isEscape) {
            # error if not invalue
            unless( $inValue ) {
               croak "Mismatched ']' : FAILED";
            }
            $self->_debug( "Adding Property: '$propertyName' "
               ."=> '$propertyValue[$propI]'\n");
   
            my $val =  $self->_tagRead($propertyName, 0, @propertyValue);
            if( defined $val ) {
               push @values, $val;
            } else {
               return 0;
            }
            $lastName = $propertyName;
            $propertyName = '';
            @propertyValue = ("");
            $propI = 0;
            $inValue = 0;
            next;
         } elsif( $char eq ':' and $self->_maybeComposed($propertyName)) {
            if($propI >= 1 ) {
               $self->err( "Too Many Compose components in value: FAILED" );
               return undef;
            }
            $propI++;
            $propertyValue[$propI] = ""; # should be redundent
            next;
         } elsif( $self->_isText($propertyName, $propI) ) {
            if( $isEscape ) {
               if( $char eq '\n' ) {
                  $char = ""; # no space
               }
               if( $char =~ /\s/ ) {
                  $char = " "; # single space
               }
               $isEscape = 0;
            } elsif( $char eq '\\' ) {
               $isEscape = 1;
               $char = "";
            } elsif( $char =~ /\n/ ) {
               # makes sure newlines are saved when they are supposed to
               $char = "\n";
            } elsif( $char =~ /\s/ ) { # all other whitespace to a space
               $char = " ";
            }
         } elsif( $self->_isSimpleText($propertyName, $propI ) ) {
            if( $isEscape ) {
               if( $char eq '\n' ) {
                  $char = ""; # no space
               }
               if( $char =~ /\s/ ) {
                  $char = " "; # single space
               }
               $isEscape = 0;
            } elsif( $char eq '\\' ) {
               $isEscape = 1;
               $char = "";
            } elsif( $char =~ /\s/ ) { # all whitespace to a space
               $char = " ";
            }
         }
         $propertyValue[$propI] .= $char;
      # outside of a value 
      } elsif( $char eq '(' ) {
         if( @values ) {
            return undef if not $self->setProperty($lastName, @values); 
            @values = ();
         }
         if($inTree) {
            $self->_debug( "Starting GameTree\n");
            if( not $self->addVariation ) {
               return undef;
            }
         } else {
            $self->_debug( "Adding GameTree to Collection\n");
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
         $self->_debug("Adding Node\n");
         if( @values ) {
            return undef if not $self->setProperty($lastName, @values); 
            @values = ();
         }
         if( not $inTree ) {
            $self->err("Attempted to start node outside"
               . "of GameTree: Failed");
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

This holds true for standard FF4 and I believe it would cause a conflict
if it was not true.

=back

=head1 TODO and KNOWN Problems

=over

=item Write Test Code

Inheritence

Game Specific Modules



=item Add methods for auto detecting gamemode, and FF[4]

Could change the inheritance method to registering a class with a
game mode.

=item finish override methods

=over

=item move

=item stone

=item point 

=back

The purpose of these subs is for users. they should map user structs
to intnernal structs. The L</compose> method should be the template for
functionality.

The default behavior will be to treat the SGF value string as the user
format. This will inturn call the _typeRead method and _typeWrite
methods.

Forexample the default use would look like:

  $sgf->property("B", $sgf->move("ab") );
  my $move = $sgf->move($sgf->property("B") );

When overrode it should look like:

  $sgf->property("B", $sgf->move(1,2) );
  my($x, $y) = $sgf->move( $sgf->property("B"));

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
