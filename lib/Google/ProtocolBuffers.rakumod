#!/usr/bin/env raku
unit module Google::ProtocolBuffers;

our proto decode($, *%params) {*}

class Varint is export {

  has blob8 $.blob;

  multi method new(Channel $c) {
    my @b;
    until $c.closed {
      @b.push: my $b = $c.receive;
      return self.bless(:blob(blob8.new(@b))) unless $b +& 128;
    }
    die "channel unexpectedly closed";
  }
  multi method new(UInt $n is copy) {
    self.bless:
      blob => blob8.new:
      gather {
	while $n ≥ 128 {
	  take ($n % 128) +| 128;
	  $n +>= 7;
	}
	take $n;
      }
  }
  method Int { [+] ($!blob.list X[+&] 127) Z[+<] (0, 7 ... *) }
}

multi decode(blob8 $b, *%params) {
  my Channel $c .= new;
  LEAVE $c.close;
  $c.send($_) for $b;
  samewith $c, |%params;
}
multi decode(Channel $c) {
  my UInt ($sum, $i);
  gather until $c.closed {
    my $tag = Varint.new($c).Int;
    my ($field, $wire-type) = $tag +> 3, $tag +& 7;
    take $field;
    given $wire-type {
      when 0 { take Varint.new($c).Int }
      when 1 { take ($c.receive xx 8).reduce: 256 * * + * }
      when 2 {
	my $length = Varint.new($c).Int;
	take blob8.new: $c.receive xx $length;
      }
      when 3|4 { !!! "deprecated" }
      when 5 { take ($c.receive xx 4).reduce: 256 * * + * }
      default {...}
    }
  }
}

our class Encoder {
  #`{{{ CHEATSHEET from 
  # https://developers.google.com/protocol-buffers/docs/encoding
  message   := (tag value)*     You can think of this as “key value”

  tag       := (field << 3) BIT_OR wire_type, encoded as varint
  value     := (varint|zigzag) for wire_type==0 |
	       fixed32bit      for wire_type==5 |
	       fixed64bit      for wire_type==1 |
	       delimited       for wire_type==2 |
	       group_start     for wire_type==3 | This is like “open parenthesis”
	       group_end       for wire_type==4   This is like “close parenthesis”

  varint       := int32 | int64 | uint32 | uint64 | bool | enum, encoded as
		  varints
  zigzag       := sint32 | sint64, encoded as zig-zag varints
  fixed32bit   := sfixed32 | fixed32 | float, encoded as 4-byte little-endian;
		  memcpy of the equivalent C types (u?int32_t, float)
  fixed64bit   := sfixed64 | fixed64 | double, encoded as 8-byte little-endian;
		  memcpy of the equivalent C types (u?int64_t, double)

  delimited := size (message | string | bytes | packed), size encoded as varint
  message   := valid protobuf sub-message
  string    := valid UTF-8 string (often simply ASCII); max 2GB of bytes
  bytes     := any sequence of 8-bit bytes; max 2GB
  packed    := varint* | fixed32bit* | fixed64bit*,
	       consecutive values of the type described in the protocol definition

  varint encoding: sets MSB of 8-bit byte to indicate “no more bytes”
  zigzag encoding: sint32 and sint64 types use zigzag encoding.
  }}}

  has %.definitions;
  has Str $.package;

  method TOP($/) { make %!definitions }
  method syntax($/) { make ~$<version> }
  method import($/) {...}

  method topLevelDef($/) {
    with $<message>  { make .made }
    with $<enum>     { make .made }
    with $<mapField> { ...        }
  }
  
  # messages
  method message($/) {
    make %!definitions{$<messageName>.made} =
      Hash.new: (type => 'message', body => $<messageBody>.made);
  }
  method package($/) {
    $!package = (~$<fullIdent>).subst('.', '-', :g);
  }
  method messageName($/) {
    make ($!package ?? "$!package-" !! '') ~ $/
  }
  method messageBody($/) {
    make reduce {$^a.append($^b.pairs)}, {}, |$<field>».made, |$<message>».made
  }
  method field($/) {
    my $label = $<label> ?? ~$<label> !! Empty;
    my $name = ~$<fieldName>;
    my $number = +$<fieldNumber>;
    my $type = ~$<type>;
    make {
      $number => Hash.new( (($label andthen :$label), :$name, :$type) ),
      $name => $number
    }
  }
  method fieldNumber($/) { make +$/ }

  method oneof($/) { !!! "NIY" }

  # enums
  method enum($/) {
    make %!definitions{$<enumName>.made} = Hash.new: (type => "enum", body => $<enumBody>.made)
  }
  method enumName($/) {
    make ($!package ?? "$!package-" !! '') ~ $/
  }
  method enumBody($/) { make Hash.new: $<enumField>».made }
  method enumField($/) { make Pair.new: ~$<ident>, +$<intLit> }

}

our package ZigZag {
  our sub encode-int32(int32 $n --> uint) { ($n +< 1) +^ ($n +> 31) }
  our sub encode-int64(int64 $n --> uint) { ($n +< 1) +^ ($n +> 64) }
}

sub wire-type(Str $type) is export {
  given $type {
    when / [u|s]?int[32|64] | bool | enum / { return 0 }
    when / s?fixed64 | double /             { return 1 }
    when / string | message /               { return 2 }
    when / s?fixed32 | float /              { return 5 }
    default { !!! "unkown type $_" }
  }
}
sub tag($field-number, $wire-type) { $field-number +< 3 +| $wire-type }

class ProtoBuf is export {
  has %.definitions handles <AT-KEY>;
  has Str $.proto-spec;
 
  multi method new(Str $proto-spec) { self.bless: :$proto-spec }
  submethod TWEAK {
    use Google::ProtocolBuffers::Grammar;
    if Google::ProtocolBuffers::Grammar.parse:
      $!proto-spec
      # attemting to remove C-style comment :
      .subst(/'//' \N* \n/,      "\n", :g)  # // ... \n
      .subst(/'/*' ~ '*/' .*? /, "\n", :g)  # /* ... */
      , actions => Encoder.new
    { %!definitions = $/.made }
    else { die "unknown proto spec format" }
  }
  
  method wire-type(Str $type) {
    given $type {
      when / [u|s]?int[32|64] | bool | enum / { return 0 }
      when / s?fixed64 | double /             { return 1 }
      when / s?fixed32 | float /              { return 5 }
      when / string / or
	self{$_}:exists && self{$_}<type> eq 'message' { return 2 }
      default { !!! "unkown type $_" }
    }
  }
  multi method FALLBACK(Str $ where /^u?int[32|64]$/, UInt $value) { Varint.new($value).blob }
  multi method FALLBACK('string', Str $str) { Varint.new($str.chars).blob ~ $str.encode; }
  multi method FALLBACK(Str $method where (%!definitions{$method}:exists), *%params) {
    my %definition = self{$method}; 
    given %definition<type> {
      when "message" {
	return %params.pairs.map:
	{
	  if %definition<body>{.key}:exists {
	    my $number = +%definition<body>{.key};
	    if $number ~~ /<digit>+/ {
	      if my $definition = %definition<body>{$number} {
		my $type = $definition<type>; 
		.key => Varint.new(tag $number, wire-type $type).blob ~
                samewith $type, .value;
	      } else { !!! "unable to find field" }
	    } else { !!! "unexpected number format" }
	  } else { !!! "unknown field \"{.key}\" for message '$method'" }
	}
      }
      default { !!! "$_ NYI" }
    }
  }
}
