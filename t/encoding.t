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


constant pb = ProtoBuf.new: q[syntax = "proto3";
message Msg {
  int32 i = 1;
  string txt = 2;
  message Msg2 {
    int32 j = 1;
  }
  Msg2 m = 3;
}
];

my $i = ^100 .pick;
my $msg = pb.definitions<Msg>;
my $msg2 = pb.definitions<Msg2>;

$msg<i>.set(53);
$msg<txt>.set("hello");
$msg2<j>.set: 577;
$msg<m>.set: $msg2;

lives-ok { $msg2.encode }, "encoding inner message";
lives-ok { $msg.encode }, "encoding outer message";

done-testing;

# vi: ft=raku
