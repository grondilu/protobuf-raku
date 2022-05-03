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

done-testing;

given ProtoBuf.new: q[syntax = "proto3"; message Msg { int32 i = 1; }] {
  my $i = ^100 .pick;
  say .Msg: :$i
}

=finish


# vi: ft=raku
