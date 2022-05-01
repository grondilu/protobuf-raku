# protobuf-raku
Google's protocol buffers in raku

## Synopsis

```raku
use Google::Protobuffers;

my ProtoBuf $pb .= new:
  q[syntax = "proto2"; message Test1 { optional int32 a = 1; }];

# encode
say $pb.Test1: a => 150; 

# decode
say $pb.Test1: blob8.new: <08 96 01>.map({:16($_)});
```
