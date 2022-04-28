#!/usr/bin/env raku
use Test;

subtest {
  use Google::ProtocolBuffers::Proto2;
  my grammar G is Google::ProtocolBuffers::Proto2 {};

  ok  q[syntax = "proto2";]                       ~~ /^<G::syntax>$/, 'syntax';
  nok q[syntax = "proto3";]                       ~~ /^<G::syntax>$/, 'syntax';

  ok q[import public "other.proto";]             ~~ /^<G::import>$/, 'import';
  ok q[package foo.bar;]                         ~~ /^<G::package>$/, 'package';
  ok q[option java_package = "com.example.foo";] ~~ /^<G::option>$/, 'option';
  ok q[int32]                                    ~~ /^<G::type>$/, 'type';

  ok $_ ~~ m/^ <G::field>$ /, qq["$_"] for q:to/FIELDS/.lines;
  optional foo.bar nested_message = 2;
  repeated int32 samples = 4 [packed=true];
  FIELDS

  nok $_ ~~ m/^ <G::field>$ /, qq["$_" failed as expected] for qq:to/FIELDS/.lines;
  optional foo.bar nested_message = 0;
  repeated int32 samples = {(19_000..19_999).pick} [packed=true];
  FIELDS

  ok q:to/GROUPS/ ~~ m/^ <G::group>$ /, 'group';
  repeated group Result = 1 {
      required string url = 2;
      optional string title = 3;
      repeated string snippets = 4;
  }
  GROUPS

  ok q:to/ONEOF/ ~~ /^<G::oneof>$/, 'oneof';
  oneof foo {
    string name = 4;
    SubMessage sub_message = 9;
  }
  ONEOF

  ok q[map<string, Project> projects = 3;] ~~ /^<G::mapField>$/, 'mapField';

  ok $_ ~~ m/^ <G::extensions>$ /, qq["$_"] for q:to/EXTENSIONS/.lines;
  extensions 100 to 199;
  extensions 4, 20 to max;
  EXTENSIONS

  ok $_ ~~ m/^ <G::reserved>$ /, qq["$_"] for q:to/RESERVED/.lines;
  reserved 2, 15, 9 to 11;
  reserved "foo", "bar";
  RESERVED

  ok q:to/ENUM/ ~~ /^<G::enum>$/, 'enum';
  enum EnumAllowingAlias {
    option allow_alias = true;
    UNKNOWN = 0;
    STARTED = 1;
    RUNNING = 2 [(custom_option) = "hello world"];
  }
  ENUM

  ok q:to/MESSAGE/ ~~ /^<G::message>$/, 'message';
  message Outer {
    option (my_option).a = true;
    message Inner {
      required int64 ival = 1;
    }
    map<int32, string> my_map = 2;
    extensions 20 to 30;
  }
  MESSAGE

  ok q:to/EXTEND/ ~~ /^<G::extend>$/, 'extend';
  extend Foo {
    optional int32 bar = 126;
  }
  EXTEND

  ok q:to/SERVICE/ ~~ /^<G::service>$/, 'service';
  service SearchService {
    rpc Search (SearchRequest) returns (SearchResponse);
  }
  SERVICE

  skip q[the 'groupMessage' entry in this example seems wrong.];
  if False {
    ok q:to/PROTO/ ~~ /^<G::proto>$/, 'proto';
    syntax = "proto2";
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
	required int64 ival = 1;
      }
      repeated Inner inner_message = 2;
      optional EnumAllowingAlias enum_field = 3;
      map<int32, string> my_map = 4;
      extensions 20 to 30;
    }
    message Foo {
      optional group GroupMessage {
	optional a = 1;
      }
    }
    PROTO
  }

}, 'proto2';

subtest {
  use Google::ProtocolBuffers::Proto3;
  my grammar G is Google::ProtocolBuffers::Proto3 {};
  ok  q[syntax = "proto3";]                       ~~ /^<G::syntax>$/, 'syntax';
  nok q[syntax = "proto2";]                       ~~ /^<G::syntax>$/, 'syntax';

  ok q[import public "other.proto";]             ~~ /^<G::import>$/, 'import';
  ok q[package foo.bar;]                         ~~ /^<G::package>$/, 'package';
  ok q[option java_package = "com.example.foo";] ~~ /^<G::option>$/, 'option';
  ok q[int32]                                    ~~ /^<G::type>$/, 'type';

  ok $_ ~~ m/^ <G::field>$ /, qq["$_"] for q:to/FIELDS/.lines;
  foo.Bar nested_message = 2;
  repeated int32 samples = 4 [packed=true];
  FIELDS

  nok $_ ~~ m/^ <G::field>$ /, qq["$_" failed as expected] for qq:to/FIELDS/.lines;
  foo.Bar nested_message = 0;
  repeated int32 samples = {(19_000..19_999).pick} [packed=true];
  FIELDS

  ok q:to/ONEOF/ ~~ /^<G::oneof>$/, 'oneof';
  oneof foo {
    string name = 4;
    SubMessage sub_message = 9;
  }
  ONEOF

  ok q[map<string, Project> projects = 3;] ~~ /^<G::mapField>$/, 'mapField';

  ok $_ ~~ m/^ <G::reserved>$ /, qq["$_"] for q:to/RESERVED/.lines;
  reserved 2, 15, 9 to 11;
  reserved "foo", "bar";
  RESERVED

  ok q:to/ENUM/ ~~ /^<G::enum>$/, 'enum';
  enum EnumAllowingAlias {
    option allow_alias = true;
    UNKNOWN = 0;
    STARTED = 1;
    RUNNING = 2 [(custom_option) = "hello world"];
  }
  ENUM

  ok q:to/MESSAGE/ ~~ /^<G::message>$/, 'message';
  message Outer {
    option (my_option).a = true;
    message Inner {
      int64 ival = 1;
    }
    map<int32, string> my_map = 2;
  }
  MESSAGE

    ok q:to/SERVICE/ ~~ /^<G::service>$/, 'service';
  service SearchService {
    rpc Search (SearchRequest) returns (SearchResponse);
  }
  SERVICE

    ok q:to/PROTO/ ~~ /^<G::proto>$/, 'proto';
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

}, 'proto3';

done-testing;

# vi: ft=raku
