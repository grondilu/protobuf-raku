#!/usr/bin/env raku
use Google::ProtocolBuffers::Grammar;
unit grammar Google::ProtocolBuffers::Proto3 is Google::ProtocolBuffers::Grammar;
# https://developers.google.com/protocol-buffers/docs/reference/proto3-spec

token version { proto3 }

rule field { [repeated]? <type> <fieldName> '=' <fieldNumber> [ \[ ~ \] <fieldOptions> ]? \; }

rule messageBody { \{ ~ \} [ <field> | <enum> | <message> | <option> | <oneof> | <mapField> | <reserved> | <emptyStatement> ]* }

rule service { service <serviceName> [ \{ ~ \} [ <option> | <rpc> | <emptyStatement> ]* ] }

rule topLevelDef { <message> | <enum> | <service> }
