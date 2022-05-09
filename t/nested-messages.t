#!/usr/bin/env raku
# https://developers.google.com/protocol-buffers/docs/encoding
use Test;

use Google::ProtocolBuffers;

constant pb = ProtoBuf.new: q:to/PROTO-END/;
syntax = 'proto3';

message A {
  message B {
    enum Toss {
      UNKNOWN = 0;
      HEADS   = 1;
      TAILS   = 2;
    }
    message C {
      message D {
        message E {
	  int32 n = 1;
	  Toss  t = 2;
	}
	E e = 1;
      }
      D d = 1;
    }
    C c = 1;
  }
  B b = 1;
}
PROTO-END

lives-ok {
   pb.encode: {
    b => { c => { d => { e => { n => 57, t => "HEADS" } } } }
  },
  name => 'A';
}, "encoding survives";

=finish


# vi: ft=raku
