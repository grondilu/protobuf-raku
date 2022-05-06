#!/usr/bin/env raku
use Test;

use Google::ProtocolBuffers::Grammar;

constant conformance-proto = "conformance.proto".IO.slurp;

ok Google::ProtocolBuffers::Grammar.parse(
  conformance-proto
  .subst(/'//' \N*? \n/, '', :g)
  .subst(/^\n*/, '', :g)
), "parsing conformance.proto";
;

done-testing;

# vi: ft=raku
