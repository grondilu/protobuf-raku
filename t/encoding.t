#!/usr/bin/env raku
# https://developers.google.com/protocol-buffers/docs/encoding
use Test;
use Google::ProtocolBuffers;

for ^1_000_000_000_000 .pick(10) {
  is $_, Varint.new(blob => Varint.new($_).blob).Int, "$_ -> varint -> $_";
}

my ($field, $b) = Google::ProtocolBuffers::decode blob8.new:
  <12 07 74 65 73 74 69 6e 67>.map: {:16($_)};
is $field, 2, 'string example - field';
is $b.decode('ascii'), 'testing', 'string example - string';


constant pb = ProtoBuf.new: q:to/PROTO-END/;
syntax = "proto3";
message Msg {
  int32 i = 1;
  string txt = 2;
  message Msg2 {
    int32 j = 1;
  }
  Msg2 m = 3;
}
PROTO-END

say pb.encode: {
  i   => 57,
  txt => "foo",
  m   => {
    j => 122
  }
}, name => "Msg";

=finish

my $msg = pb.Msg;
my $msg2 = pb.Msg2;
my $msg3 = pb.Msg2;

lives-ok {
  $msg.i = ^100 .pick;
  $msg.txt = "hello";
  $msg2.j = ^1_000_000 .pick;
  $msg3.j = ^1_000_000 .pick;
  $msg.m = $msg2;
}, "setting fields with correct types";

isnt $msg2.j, $msg3.j, "instanciation";

dies-ok {
  $msg.i = "foo";
  $msg.txt = ^100 .pick;
  $msg2.j = "bar";
  $msg.m = pi;
}, "dying when setting fields with incorrect types";

lives-ok { $msg2.encode }, "encoding inner message";
lives-ok { $msg.encode }, "encoding outer message";

done-testing;

# vi: ft=raku
