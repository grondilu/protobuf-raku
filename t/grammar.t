#!/usr/bin/env raku
use Test;

use Google::ProtocolBuffers::Grammar;
my grammar G is Google::ProtocolBuffers::Grammar {};

my $proto2 = q:to/PROTO2/;
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
  PROTO2

my $proto3 = q:to/PROTO3/;
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
  PROTO3

ok G.parse($proto2), "proto2 example passes";
nok G.parse($proto2.subst(/proto2/, "proto3")), "proto2 example fails when claiming to be a proto3";

ok G.parse($proto3), "proto3 example passes";
nok G.parse($proto3.subst(/proto3/, "proto2")), "proto3 example fails when claiming to be a proto2";

done-testing;

# vi: ft=raku
