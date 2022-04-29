#!/usr/bin/env raku
unit module Google::ProtocolBuffers;

sub varint-encode(UInt $n is copy --> blob8) is export {
  blob8.new: gather {
    while $n ≥ 128 {
      take ($n % 128) +| 128;
      $n +>= 7;
    }
    take $n;
  }
}
