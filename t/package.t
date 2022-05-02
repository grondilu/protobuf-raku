#!/usr/bin/env raku
# https://developers.google.com/protocol-buffers/docs/encoding
use Test;
use Google::ProtocolBuffers;

my ProtoBuf $pb .=new: q:to/PROTO-END/;
	syntax = "proto2";
	message Test { optional int32 a = 1; };
        package foo;
	message Test { optional int32 b = 1; };
        package foo.bar;
	message Test { optional int32 c = 1; };
	PROTO-END

ok  $pb.definitions<Test><body><a>:exists;
nok $pb.definitions<Test><body><b>:exists;
ok  $pb.definitions<foo-Test><body><b>:exists;
nok $pb.definitions<foo-Test><body><c>:exists;
ok  $pb.definitions<foo-bar-Test><body><c>:exists;
nok $pb.definitions<foo-bar-Test><body><a>:exists;
nok $pb.definitions<foo-bar-Test><body><b>:exists;

done-testing;

=finish


# vi: ft=raku
