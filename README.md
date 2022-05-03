# protobuf-raku
Google's protocol buffers in raku

## Synopsis

```raku
use Google::Protobuffers;

my ProtoBuf $pb .= new: q:to/PROTO-END/;
	syntax = "proto2";
	message Test1 { optional int32 a = 1; };
	PROTO-END

# encode
say $pb.Test1: a => 150; 

# decode
say $pb.Test1: blob8.new: <08 96 01>.map({:16($_)});
```

## Disclaimer

This is a work in progress.

I approach this differently than for any other protobuf library I know of.
Namely, I don't generate code.  Perhaps I will once the rakuast branch
of raku is mature, but in the meantime, I just generate a Hash storing
a the structures of all definitions in the `.proto` files.  I then
use the `FALLBACK` mechanism to process encoding or decoding requests.
