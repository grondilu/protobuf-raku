#!/usr/bin/env raku
# https://developers.google.com/protocol-buffers/docs/encoding
use Test;

use Google::ProtocolBuffers;

given ProtoBuf.new: q:to/PROTO-END/
	syntax = "proto3";
	enum EnumAllowingAlias {
	  option allow_alias = true;
	  UNKNOWN = 0;
	  STARTED = 1;
	  RUNNING = 2 [(custom_option) = "hello world"];
	}
	PROTO-END
{
  is .definitions<EnumAllowingAlias><UNKNOWN>, 0;
  is .definitions<EnumAllowingAlias><STARTED>, 1;
  is .definitions<EnumAllowingAlias><RUNNING>, 2;
}

done-testing;

=finish


# vi: ft=raku
