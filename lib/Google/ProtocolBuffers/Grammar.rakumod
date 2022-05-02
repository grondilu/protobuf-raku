#!/usr/bin/env raku
unit grammar Google::ProtocolBuffers::Grammar;

rule TOP {
  :our $*VERSION;
  <proto>
}
rule proto {
  <syntax> [
    | <import>
    | <package>
    | <option>
    | <topLevelDef>
    | <emptyStatement> 
  ]*
}
rule syntax { syntax '=' [\' <version> \' | \" <version> \" ] \; }

token version  { proto(<[23]>) { $*VERSION = +$/[0] } }

token letter       { <alpha> }
token decimalDigit { <digit> }
token octalDigit   { <[0 .. 7]> }
token hexDigt      { <xdigit> }

#token ident { <.letter> [ <.letter> | <.decimalDigit> | '_' ]* }
token fullIdent { <ident>+ % \. }

token messageName { <.ident> }
token enumName    { <.ident> }
token fieldName   { <.ident> }
token oneofName   { <.ident> }
token mapName     { <.ident> }
token serviceName { <.ident> }
token rpcName     { <.ident> }
token streamName  { <.ident> }
token groupName   { <capitalLetter> [ <letter> | <decimalDigit> | '_' ]* }

token capitalLetter { <alpha> }
token label {
   [ required | optional | repeated ]
  { die "labels are only defined for proto2" unless $*VERSION == 2 }
}

token messageType { '.'? [ <ident> '.' ]* <messageName> }
token enumType    { '.'? [ <ident> '.' ]* <enumName>    }

token intLit     { <decimalLit> | <octalLit> | <hexLit> }
token decimalLit { <[1 .. 9]> <decimalDigit>* }
token octalLit   { 0 <octalDigit>*   }
token hexLit     { 0 <[xX]> <hexDigt>+ }

token floatLit {
  | [ <decimals> '.' <decimals>? <exponent>? | <decimals> <exponent> | '.' <decimals> <exponent>? ]
  | inf
  | nan
}
token decimals { <decimalDigit>+ }
token exponent { <[eE]> <[+-]> <decimals> }

token boolLit  { true | false }

regex strLit { [ \' <charValue>* \' || \" <charValue>* \" ] }

token charValue  { <hexEscape> | <octEscape> | <charEscape> | <-[\0\n\\]> }
token hexEscape  { \\ <[xX]> <hexDigit> ** 2 }
token octEscape  { \\ <octalDigit> ** 3 }
token charEscape { \\ <[abfnrtv\\'"]> }

token emptyStatement { \; }

token constant { <fullIdent> | [ <[+-]> <intLit> ] | [ <[-+]> <floatLit> ] | <strLit> | <boolLit> }
rule import { import [ weak | public ]? <strLit> \; }
rule package { package <fullIdent> \; }
rule option { option <optionName> '=' <constant> \; }
token optionName { [ <ident> | \( <fullIdent> \) ] [ "." <ident> ]* }

token type {
 < double float int32 int64 uint32 uint64 sint32 sint64 fixed32 fixed64 sfixed32 sfixed64 bool string bytes >
 | <messageType> | <enumType>
}
token fieldNumber { <.intLit> <?{ 1 ≤ $/ < 2**29 && $/ == (19_000 .. 19_999).none }> }
 
rule field {
  [
    | <?{ $*VERSION == 2 }> <label>
    | <?{ $*VERSION == 3 }> [repeated]?
  ] <type> <fieldName> '=' <fieldNumber> [ \[ ~ \] <fieldOptions> ]? \; 
}
rule fieldOptions { <fieldOption>+ % \, }
rule fieldOption  { <optionName> \= <constant> }

rule oneof { oneof <oneofName> \{ ~ \} [ <option> | <oneofField> | <emptyStatement> ]* }
rule oneofField { <type> <fieldName> '=' <fieldNumber> [ \[ ~ \] <fieldOptions> ]? \; }

rule mapField { map [ \< ~ \> [ <keyType> \, <type> ] ] <mapName> '=' <fieldNumber> [ \[ ~ \] <fieldOptions> ]? \; }
token keyType { < int32 int64 uint32 uint64 sint32 sint64 fixed32 fixed64 sfixed32 sfixed64 bool string > }

rule reserved { reserved [ <ranges> | <strFieldNames> ] \; }
rule ranges { <range>+ % \, }
rule range { <intLit> [ to [ <intLit> | max ] ]? }
rule strFieldNames { <strFieldName>+ % \, }
regex strFieldName { [ \' ~ \' <fieldName> ] | [ \" ~ \" <fieldName> ] }

rule enum { enum <enumName> <enumBody> }
rule enumBody { \{ [ <option> | <enumField> | <emptyStatement> ]* \} }
rule enumField { <ident> '=' '-'? <intLit> [ \[ ~ \] [ <enumValueOption>+ % \, ] ]? \; }
rule enumValueOption { <optionName> '=' <constant> }

rule message { message <messageName> <messageBody> }
rule messageBody {
  \{ ~ \} [
  | <field> | <enum> | <message>
  | <?{ $*VERSION == 2 }> [ <extend> | <extensions> | <group> ]
  | <option> | <oneof> | <mapField> | <reserved> | <emptyStatement> ]*
}

rule service {
  service <serviceName> [
  \{ ~ \} [
    | <option> | <rpc>
    | <?{ $*VERSION == 2 }> <stream>
    | <emptyStatement> ]*
  ]
}

rule stream {
  stream <streamName>
  [ '(' ~ ')' <messageType> ** 2 % ',' ]
  [[ '{' ~ '}' [ <option> | <emptyStatement> ]* ]? | ';' ]?
  { die "stream are only defined in proto2" unless $*VERSION == 2 }
}
rule extensions {
  extensions <ranges> \;
  { die "extensions are only defined in proto2" unless $*VERSION == 2 }
}
rule extend {
  extend <messageType> '{' ~ '}' [ <field> | <group> | <emptyStatement> ]*
  { die "extensions are only defined in proto2" unless $*VERSION == 2 }
}

rule group {
  <label> group <groupName> '=' <fieldNumber> <messageBody>
  {
    die "groups are only defined in proto2" unless $*VERSION == 2;
    warn "groups are deprecated";
  }
}

rule rpc {
  rpc <rpcName>
    [ \( ~ \) [ [stream]? <messageType> ] ]
    returns
      [ \( ~ \) [ [stream]? <messageType> ] ]
      [ [ \{ ~ \} [ <option> | <emptyStatement> ]? ]? | \; ]?
}

rule topLevelDef {
  <message> | <enum>
  | <?{ $*VERSION == 2 }> <extend>
  | <service>
}


