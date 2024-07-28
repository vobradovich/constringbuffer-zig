# Genereic stack allocated Ring Buffer 

Simple Ring Buffer implementation with generic indexes type and item type.
Max capacity N of this Ring Buffer is 2^bits-1.
Uses only wrapping operations on indexes.
This means that whether the ring buffer is full or empty can be distinguished by looking at the difference between the read and write indices without adding an extra boolean flag or having to reserve a slot in the buffer.

### Use

Create a new ring buffer with index type `u8` and item type `usize`.
The maximum capacity of this ring buffer is `255`.

```zig
var b = ConstGenericRingBuffer(u8, 255, usize).init();
try testing.expect(b.is_empty());
try b.write(100500);
try testing.expectEqual(100500, b.read());
```