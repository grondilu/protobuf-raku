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
  .map({Pair.new: |$_}) given
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
      oneofs => $<oneof>».made,
      definitions => (
	|$<message>».made,
	|$<enum>».made,
      )
    )
  }
  method field($/) {
    my $name = ~$<fieldName>;
    my $number = +$<fieldNumber>;
    my $type = ~$<type>;
    make %( :$name, ($<label> andthen :label(~$_)), :$number, :$type )
  }
  method fieldNumber($/) { make +$/ }

  method enum($/)  {
    make %(
      :name($<enumName>.made),
      :type<enum>,
      :hash(Hash.new: $<enumBody><enumField>».made),
    )
  }
  method enumName($/)  { make ~$/ }
  method enumField($/) { make Pair.new: ~$<ident>, +$<enumValue> }

  method oneof($/) {
    make %(
      :name($<oneofName>.made)
      :type<oneof>,
      :fields($<oneofField>».made)
    )
  }
  method oneofName($/) { make ~$/ }
  method oneofField($/) {
    make %(
      :type(~$<type>),
      :name(~$<fieldName>),
      :number(+$<fieldNumber>)
    )
  }
  # TODO
  method package($/) {...}

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

  sub look-up(Str $name, *@definitions) {
    my @look-ups = @definitions.map: *.classify({.<name>});
    die "could not look up '$name'" unless
      my %definitions = @look-ups.first({$_{$name}:exists});
    die "duplicate definition"    if %definitions{$name} > 1;
    return %definitions{$name}.shift;
  }
 
  # message encoding
  multi method encode(%hash, Str :$name, :@definitions = (%!made<definitions>,) --> blob8) {
    my $definition = look-up $name, |@definitions;
    die "$name is not a message, so it can't be initialized by a hash" unless $definition<type> eq 'message';
    my %fields = $definition<body><fields>.classify(*<name>);
    my %oneofs = $definition<body><oneofs>.classify(*<name>);
    [~] gather for %hash.pairs -> $pair {
      my ($key, $value) = $pair.kv;
      die "'$key' defined both as a oneof and normal field" if (%fields,%oneofs).all{$key}:exists;
      my $field;
      if %fields{$key}:exists {
	die "duplicated field '$key'" if %fields{$key} > 1;
	$field = %fields{$key}.pick;
      } elsif %oneofs{$key}:exists {
        die "duplicated oneof '$key'" if %oneofs{$key} > 1;
        my $oneof = %oneofs{$key}.pick;
	with $oneof<fields>.classify(*<name>){$value.key} {
          die "duplicate oneof field '{$value.key}'" if .elems > 1;
          $field = .pick;
        } else { die "unkown oneof field '{$value.key}'" }
        die "unexpected value format for oneof entry" unless $value ~~ Pair;
        ($key, $value) = $value.kv;
      } else { die "unknown (oneof)field '$key'" }

      given $field<type> {
        when /^<[su]>?int[32|64]$/ {
	  die "integer value was expected for field '$key'" unless $value ~~ Int;
          take Varint.new($field<number> +< 3).blob ~ Varint.new($value).blob;
	}
        when "string" {
	  die "string value was expected for field '$key'"  unless $value ~~ Str;
          my $encoded-string = blob8.new: $value.encode;
          take Varint.new($field<number> +< 3 +| 2).blob ~ Varint.new($encoded-string.elems).blob ~ $encoded-string;
	}
        default {
          my $definition = look-up $_, |
          my @definitions = $OUTERS::definition<body><definitions>, |@OUTERS::definitions;
          given $definition<type> {
            when 'message' {
              my $msg = samewith $value, :name($_), |@definitions;
              take Varint.new($field<number> +< 3 +| 2).blob ~
                   Varint.new($msg.elems).blob ~ $msg;
            }
            when 'enum' {
              take Varint.new($field<number> +< 3).blob ~
                   Varint.new($definition<hash>{$value}).blob
            }
            default { die "unknown type '{$definition<type>}'" }
	  }
	}
      }
    }
  }
  
}

=finish

