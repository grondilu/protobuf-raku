#!/usr/bin/env raku
use Test;

use Google::ProtocolBuffers::Grammar;

subtest {
  ok Google::ProtocolBuffers::Grammar.parse(q[syntax = "proto2";]), "no message";
}, "proto2";

subtest {
  ok Google::ProtocolBuffers::Grammar.parse(q[syntax = "proto3";]), "no message";

  ok Google::ProtocolBuffers::Grammar.parse(q:to/PROTO-END/), "empty message";
  syntax = "proto3";
  message A {}
  PROTO-END

  ok Google::ProtocolBuffers::Grammar.parse(q:to/PROTO-END/), "one-field message";
  syntax = "proto3";
  message A {
    int32 n = 1;
  }
  PROTO-END

  ok Google::ProtocolBuffers::Grammar.parse(q:to/PROTO-END/), "embedded message";
  syntax = "proto3";
  message A {
    int32 n = 1;
    message B {
    }
  }
  PROTO-END
}, "proto3";

done-testing;

=finish

# vi: ft=raku
