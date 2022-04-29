#!/usr/bin/env raku
# https://developers.google.com/protocol-buffers/docs/encoding
use Test;

use Google::ProtocolBuffers;
use Google::ProtocolBuffers::Proto2;
#use Google::ProtocolBuffers::Encoder;

package ZigZag {
  our sub encode-int32(int32 $n --> uint) { ($n +< 1) +^ ($n +> 31) }
  our sub encode-int64(int64 $n --> uint) { ($n +< 1) +^ ($n +> 64) }
}

sub wire-type(Str $type) {
  given $type {
    when / [u|s]?int[32|64] | bool | enum / { return 0 }
    when / s?fixed64 | double /             { return 1 }
    when / string /                         { return 2 }
    when / s?fixed32 | float /              { return 5 }
    default {...}
  }
}

class Encoder {
  has @.array;
  multi method new(@array) { self.bless: :@array }
  method TOP($/) {
    make [~] $<proto><topLevelDef>».made
      .map: -> &f { &f(@!array[$++]) }
  }
  method message($/) {
    my $name = ~$<messageName>;
    my $messageBody = $<messageBody>;
    make sub (@array) {
      [~] $messageBody<field>».made
	.map: -> &f { &f(@array[$++]) }
    }
  }
  method field($/) {
    my $name = ~$<fieldName>;
    my $number = +$<fieldNumber>;
    my $type = ~$<type>;
    make sub ($value) {
      blob8.new: do given $type {
        when 'int32'  {
	  varint-encode($number +< 3 +| wire-type($_))
          ~ varint-encode $value
	}
	when 'string' {
	  varint-encode($number +< 3 +| wire-type($_))
	    ~ blob8.new($value.chars)
	    ~ $value.encode
	}
        default {...}
      }
    }
  }
  method topLevelDef($/) {
    if $<message> { make $<message>.made }
    else {...}
  }
}   
    
ok .made ~~ blob8.new: <08 96 01>.map({:16($_)}) given Google::ProtocolBuffers::Proto2.parse:
  q[syntax = "proto2"; message Test1 { optional int32 a = 1; }],
  actions => Encoder.new:
  [ 
    # Test1
    [
      150, # a
    ],
  ]
;

ok .made ~~ blob8.new: <12 07 74 65 73 74 69 6e 67>
  .map({:16($_)})
 given Google::ProtocolBuffers::Proto2.parse:
  q[syntax = "proto2"; message Test2 { optional string b = 2; }],
  actions => Encoder.new:
  [ 
    # Test2
    [
      "testing", # b
    ],
  ]
;



# vi: ft=raku
