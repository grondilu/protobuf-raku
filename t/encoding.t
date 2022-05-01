#!/usr/bin/env raku
# https://developers.google.com/protocol-buffers/docs/encoding
use Test;

use Google::ProtocolBuffers;
use Google::ProtocolBuffers::Proto2;
#use Google::ProtocolBuffers::Encoder;


for ^1_000_000_000 .pick(100) {
  is $_, Varint.new(blob => Varint.new($_).blob).Int, "$_ -> varint -> $_";
}


my ($field, $b) = Google::ProtocolBuffers::decode blob8.new:
  <12 07 74 65 73 74 69 6e 67>.map: {:16($_)};
is $field, 2, 'string example - field';
is $b.decode('ascii'), 'testing', 'string example - string';

my ProtoBuf $pb .= new:
  q[syntax = "proto2"; message Test1 { optional int32 a = 1; }]
;

is $pb.Test1(a => 150), blob8.new(8, 150, 1);

done-testing;

=finish


# vi: ft=raku
