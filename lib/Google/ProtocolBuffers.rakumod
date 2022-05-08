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
  start { $c.send($_) for $b; $c.close }
  samewith $c, |%params;
}
multi decode(Channel $c) {
  my UInt ($sum, $i);
  .rotor(2)
  .map({Pair.new: |$_})
  given gather until $c.closed {
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

our class Compiler {

  method TOP($/) {
    make $<proto>.made;
  }
  method proto($/) { make %( version => $<syntax>.made, definitions => $<topLevelDef>».made ) }
  method syntax($/) { make +$<version>[0] }
  method import($/) {...}

  method topLevelDef($/) {
    with $<message>  { make .made }
    with $<enum>     { make .made }
    with $<mapField> { ...        }
  }
  
  # messages
  method message($/) {
    make %( :name($<messageName>.made), :body($<messageBody>.made), :type<message> );
  }
  method messageName($/) { make ~$/ }
  method messageBody($/) {
    make %(
      fields => $<field>».made,
      definitions => $<message>».made,
    )
  }
  method field($/) {
    my $name = ~$<fieldName>;
    my $number = +$<fieldNumber>;
    my $type = ~$<type>;
    make %( :$name, ($<label> andthen :label(~$_)), :$number, :$type )
  }
  method fieldNumber($/) { make +$/ }

  # TODO
  method package($/) {...}
  method oneof($/) {...}
  method enum($/)  {...}
}

our package ZigZag {
  our sub encode-int32(int32 $n --> uint) { ($n +< 1) +^ ($n +> 31) }
  our sub encode-int64(int64 $n --> uint) { ($n +< 1) +^ ($n +> 64) }
}

class ProtoBuf is export {
  has Str $.proto-spec;
  has %!made;
 
  multi method new(Str $proto-spec) { self.bless: :$proto-spec }
  submethod TWEAK {
    use Google::ProtocolBuffers::Grammar;
    if Google::ProtocolBuffers::Grammar.parse:
      $!proto-spec
      # attemting to remove C-style comment :
      .subst(/'//' \N* \n/,      "\n", :g)  # // ... \n
      .subst(/'/*' ~ '*/' .*? /, "\n", :g)  # /* ... */
      , actions => Compiler.new
    { %!made = $/.made }
    else { die "unknown proto spec format" }
  }
  multi method encode(%hash, Str :$name, :@definitions = %!made<definitions> --> blob8) {
    my %definitions = @definitions.grep({.<type> eq 'message'}).classify(*<name>);
    die "unknown message '$name'" unless %definitions{$name}:exists;
    die "duplicate definition"    if %definitions{$name} > 1;
    my $definition = %definitions{$name}.shift;
    my %fields = $definition<body><fields>.classify(*<name>);
    [~] gather for %hash.kv -> $key, $value {
      die "unknown field $key" unless %fields{$key} == 1;
      my $field = %fields{$key}.pick;
      given $field<type> {
        when /^<[su]>?int[32|64]$/ {
	  die "integer value was expected for field '$key'" unless $value ~~ Int;
          take blob8.new($field<number> +< 3) ~ Varint.new($value).blob;
	}
        when "string" {
	  die "string value was expected for field '$key'"  unless $value ~~ Str;
          my $encoded-string = blob8.new: $value.encode;
          take blob8.new($field<number> +< 3 +| 2) ~ blob8.new($encoded-string.elems) ~ $encoded-string;
	}
        default {
          my $msg;
          try $msg = samewith $value, :name($_), :definitions($definition<body><definitions>);
          try $msg = samewith $value, :name($_), :@definitions if $!;
          die "could not make submessage $key of type $_" if $!;
          take blob8.new($field<number> +< 3 +| 2, $msg.elems) ~ $msg;
	}
      }
    }
  }
  
}

=finish

