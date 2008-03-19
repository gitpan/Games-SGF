use Test::More;
sub sgf_func {
   my $sgf = shift;
   my $func = shift;
   my $name = shift;

   my( @args ) = @_;
   my( @return ) = ();

   my $code = $sgf->can($func);
   if( $code ) {
      @return = &$code( $sgf, @args );
      if( $return[0]  ) {
         pass( "call $func - $name" );
         return @return;
      } else {
         fail( "call $func - $name" );
         diag( "Call Failed: " . $Games::SGF::errstr );
         return undef;
      }
   } else {
      fail( "call $func - $name" );
      diag( "Call Failed: $func not found\n" );
      return undef;
   }
}

sub tag_eq {
   my $sgf = shift;
   my $name = shift;
   my( %tags ) = @_;

   TAG: foreach my $t( keys %tags ) {
      my $values = $sgf->property($t);
      if( not $values ) {
         fail( "$t - $name" );
         diag( " Parser returned error: " . $Games::SGF::errstr);
         next TAG;
      }
      if( ref $tags{$t} eq 'ARRAY' ) {
         for( my $i = 0; $i < @$values; $i++ ) {
            if( $sgf->isComposed($values->[$i]) && $sgf->isComposed($tags{$t}->[$i]) ) {
               if( not test_compose( $values->[$i], $tags{$t}->[$i] ) ) {
                  TODO: {
                     local $TODO = "This maybe a fault of the test script\nfor not handling lists in compoed";
                     fail("$t - $name");
                     #diag("Got composed( " . join(', ', @{$values->[$i]}) . " )\tExpected: ( " . join(', ',@{$tags->[$i]}) . " )\n");
                     next TAG;
                  }
               }
            } elsif(ref $values->[$i] eq ref $tags{$t}->[$i]) {
               unless( scalar @{$values->[$i]} == scalar @{$tags{$t}->[$i]} ) {
                  fail( "$t - $name");
                  diag("Got List lengths( " . join(', ', @{$values->[$i]}) . " )\tExpected: ( " . join(', ',@{$tags->[$i]}) . " )\n");
                  next TAG;
               }
               for( my $n = 0; $n < @{$values->[$i]}; $n++) {
                  unless( equal( $values->[$i]->[$n], $tags{$t}->[$i]->[$n] )) {
                     fail( "$t - $name");
                     diag("Got List( " . join(', ', @{$values->[$i]}) . " )\tExpected: ( " . join(', ',@{$tags->[$i]}) . " )\n");
                     next TAG;
                  }
               }
            } else {
               if( not equal( $values->[$i], $tags{$t}->[$i] )) {
                  fail("$t - $name");
                  diag("Got $t value( " . $values->[$i] . " )\tExpected: ( " . $tags{$t}->[$i] . " )\n");
                  next TAG;
               }
            }
         }
         pass( "$t - $name" );
      } else {
         if(equal($values->[0], $tags{$t})) {
            pass( "$t - $name");
         } else {
            fail( "$t - $name");
            diag( "Expected: ('" . $tags{$t} . "') Got: ('" . join( "', '", @$values) . "')\n");
            next TAG;
         }
      }
   }
}
sub test_compose {
   my $a = shift;
   my $b = shift;
   
   return equal( $a->[0], $b->[0]) and equal( $a->[1], $b->[1] );
}
sub equal {
   my $a = shift;
   my $b = shift;

   if( isNumber($a) and isNumber($b) ) {
      return $a == $b;
   } else {
      return $a eq $b;
   }
}
sub isNumber {
   return $_[0] =~ /^[+-]?\d+\.?\d*$/;
}
sub sgf_ok {
   my $bool = shift;
   my $name = shift;
   if( $bool ) {
      pass( $name );
   } else {
      fail( $name );
      diag( "Parser Error: " . $Games::SGF::errstr );
   }
}

1;
