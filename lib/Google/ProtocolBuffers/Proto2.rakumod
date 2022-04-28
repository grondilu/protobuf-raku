#!/usr/bin/env raku
use Google::ProtocolBuffers;
unit grammar Google::ProtocolBuffers::Proto2 is Google::ProtocolBuffers;
# https://developers.google.com/protocol-buffers/docs/reference/proto2-spec

token version { proto2 }
token capitalLetter { <alpha> }

token streamName { <ident> }
token groupName  { <capitalLetter> [ <letter> | <decimalDigit> | '_' ]* }

token label { required | optional | repeated }
rule field { <label> <type> <fieldName> '=' <fieldNumber> [ \[ ~ \] <fieldOptions> ]? \; }

rule group { <label> group <groupName> '=' <fieldNumber> <messageBody> }

rule extensions { extensions <ranges> \; }

rule messageBody { \{ ~ \} [
    <field> | <enum> | <message> | <extend> | <extensions> | <group> |
    <option> | <oneof> | <mapField> | <reserved> | <emptyStatement>
  ]*
}

rule extend { extend <messageType> '{' ~ '}' [ <field> | <group> | <emptyStatement> ]* }

rule service { service <serviceName> [ \{ ~ \} [ <option> | <rpc> | <stream> | <emptyStatement> ]* ] }
rule stream {
  stream <streamName>
  [ '(' ~ ')' <messageType> ** 2 % ',' ]
  [[ '{' ~ '}' [ <option> | <emptyStatement> ]* ]? | ';' ]?
}

rule topLevelDef { <message> | <enum> | <extend> | <service> }

rule TOP { <proto> }
