#!/usr/bin/env raku
use Test;

use Google::ProtocolBuffers;

ok q[syntax = "proto3";]                       ~~ /^<Google::ProtocolBuffers::syntax>$/, 'proto3';
ok q[import public "other.proto";]             ~~ /^<Google::ProtocolBuffers::import>$/, 'import';
ok q[package foo.bar;]                         ~~ /^<Google::ProtocolBuffers::package>$/, 'package';
ok q[option java_package = "com.example.foo";] ~~ /^<Google::ProtocolBuffers::option>$/, 'option';
ok q[int32]                                    ~~ /^<Google::ProtocolBuffers::type>$/, 'type';

ok $_ ~~ m/^ <Google::ProtocolBuffers::field>$ /, qq["$_"] for q:to/FIELDS/.lines;
foo.Bar nested_message = 2;
repeated int32 samples = 4 [packed=true];
FIELDS

ok q:to/ONEOF/ ~~ /^<Google::ProtocolBuffers::oneof>$/, 'oneof';
oneof foo {
    string name = 4;
    SubMessage sub_message = 9;
}
ONEOF

ok q[map<string, Project> projects = 3;] ~~ /^<Google::ProtocolBuffers::mapField>$/, 'mapField';

ok $_ ~~ m/^ <Google::ProtocolBuffers::reserved>$ /, qq["$_"] for q:to/RESERVED/.lines;
reserved 2, 15, 9 to 11;
reserved "foo", "bar";
RESERVED

ok q:to/ENUM/ ~~ /^<Google::ProtocolBuffers::enum>$/, 'enum';
enum EnumAllowingAlias {
  option allow_alias = true;
  UNKNOWN = 0;
  STARTED = 1;
  RUNNING = 2 [(custom_option) = "hello world"];
}
ENUM

ok q:to/MESSAGE/ ~~ /^<Google::ProtocolBuffers::message>$/, 'message';
message Outer {
  option (my_option).a = true;
  message Inner {
    int64 ival = 1;
  }
  map<int32, string> my_map = 2;
}
MESSAGE

ok q:to/SERVICE/ ~~ /^<Google::ProtocolBuffers::service>$/, 'service';
service SearchService {
  rpc Search (SearchRequest) returns (SearchResponse);
}
SERVICE

ok q:to/PROTO/ ~~ /^<Google::ProtocolBuffers::proto>$/, 'proto';
syntax = "proto3";
import public "other.proto";
option java_package = "com.example.foo";
enum EnumAllowingAlias {
  option allow_alias = true;
  UNKNOWN = 0;
  STARTED = 1;
  RUNNING = 2 [(custom_option) = "hello world"];
}
message Outer {
  option (my_option).a = true;
  message Inner {
    int64 ival = 1;
  }
  repeated Inner inner_message = 2;
  EnumAllowingAlias enum_field =3;
  map<int32, string> my_map = 4;
}
PROTO

done-testing;

# vi: ft=raku
