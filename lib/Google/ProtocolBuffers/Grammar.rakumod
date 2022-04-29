#!/usr/bin/env raku
unit grammar Google::ProtocolBuffers::Grammar;

token version  { proto<[23]> }

token letter       { <alpha> }
token decimalDigit { <digit> }
token octalDigit   { <[0 .. 7]> }
token hexDigt      { <xdigit> }

#token ident { <.letter> [ <.letter> | <.decimalDigit> | '_' ]* }
token fullIdent { <ident>+ % \. }

token messageName { <ident> }
token enumName    { <ident> }
token fieldName   { <ident> }
token oneofName   { <ident> }
token mapName     { <ident> }
token serviceName { <ident> }
token rpcName     { <ident> }

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
rule syntax { syntax '=' [\' <version> \' | \" <version> \" ] \; }
rule import { import [ weak | public ]? <strLit> \; }
rule package { package <fullIdent> \; }
rule option { option <optionName> '=' <constant> \; }
token optionName { [ <ident> | \( <fullIdent> \) ] [ "." <ident> ]* }

token type {
 < double float int32 int64 uint32 uint64 sint32 sint64 fixed32 fixed64 sfixed32 sfixed64 bool string bytes >
 | <messageType> | <enumType>
}
token fieldNumber { <intLit> <?{ 1 ≤ $<intLit> < 2**29 && $<intLit> == (19_000 .. 19_999).none }> }
 
rule field {...}
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
rule messageBody {...}

rule service {...}
rule rpc {
  rpc <rpcName>
    [ \( ~ \) [ [stream]? <messageType> ] ]
    returns
      [ \( ~ \) [ [stream]? <messageType> ] ]
      [ [ \{ ~ \} [ <option> | <emptyStatement> ]? ]? | \; ]?
}

rule proto { <syntax> [ <import> | <package> | <option> | <topLevelDef> | <emptyStatement> ]* }

rule TOP { <proto> }
