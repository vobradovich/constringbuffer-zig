const std = @import("std");
const ringbuffer = @import("lib.zig");
const testing = std.testing;

pub fn main() !void {
    var t = try std.time.Timer.start();
    const iters = 100_000_000;
    var b = ringbuffer.ConstGenericRingBuffer(u8, 3, u8).init();
    for (0..iters) |_| {
        try testing.expect(b.is_empty());
        try b.write(1);
        try testing.expect(!b.is_empty());
        try testing.expect(!b.is_full());
        try b.write(2);
        try testing.expect(!b.is_full());
        try b.write(3);
        try testing.expect(b.is_full());
        try testing.expectError(error.Full, b.write(4));
        try testing.expectEqual(1, b.read());
        try b.write(4);
        try testing.expect(b.is_full());
        try testing.expectEqual(2, b.read());
        try testing.expect(!b.is_full());
        try testing.expectEqual(3, b.read());
        try testing.expect(!b.is_full());
        try testing.expectEqual(4, b.read());
        try testing.expect(!b.is_full());
        try testing.expectEqual(null, b.read());
        try testing.expect(!b.is_full());
        try testing.expect(b.is_empty());
    }

    std.debug.print("{} iterations takes {}ms.\n", .{ iters, t.read() / 1_000_000 });
}
