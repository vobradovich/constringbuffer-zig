const std = @import("std");
const testing = std.testing;

pub fn ConstRingBuffer(comptime N: comptime_int, comptime T: type) type {
    return ConstGenericRingBuffer(usize, N, T);
}

/// Simple Ring Buffer implementation with generic indexes type.
/// Max capacity N of this Ring Buffer is 2^bits-1.
/// Uses only wrapping operations on indexes.
/// This means that whether the ring buffer is full or empty can be distinguished by looking at the difference between the read and write indices without adding an extra boolean flag or having to reserve a slot in the buffer.
pub fn ConstGenericRingBuffer(comptime INT: type, comptime N: INT, comptime T: type) type {
    comptime std.debug.assert(N > 0);
    return struct {
        read_idx: INT = 0,
        write_idx: INT = 0,
        buffer: [N]T = undefined,

        const Self = @This();

        pub fn init() Self {
            return .{};
        }

        fn insert(self: *Self, item: T) void {
            const idx = self.write_idx % N;
            self.buffer[idx] = item;
            self.write_idx +%= 1;
        }

        /// Write `T` into the ring buffer. Returns `error.Full` if the ring buffer is full.
        pub fn write(self: *Self, item: T) !void {
            if (self.is_full()) {
                return error.Full;
            }
            self.insert(item);
        }

        /// Write `T` into the ring buffer. If the ring buffer is full, the oldest byte is overwritten.
        pub fn push(self: *Self, item: T) void {
            if (self.is_full()) {
                self.read_idx +%= 1;
            }
            self.insert(item);
        }

        /// Consume a `T` from the ring buffer and return it. Returns null if the ring buffer is empty.
        pub fn read(self: *Self) ?T {
            if (self.is_empty()) {
                return null;
            }
            const idx = self.read_idx % N;
            self.read_idx +%= 1;
            return self.buffer[idx];
        }

        /// Returns `true` if the ring buffer is empty and `false` otherwise.
        pub fn is_empty(self: *Self) bool {
            return self.write_idx == self.read_idx;
        }

        /// Returns `true` if the ring buffer is full and `false` otherwise.
        pub fn is_full(self: *Self) bool {
            return (self.write_idx -% self.read_idx) == N;
        }

        /// Returns the length of the written data
        pub fn len(self: *Self) usize {
            return self.write_idx -% self.read_idx;
        }
    };
}

test "ConstRingBuffer write" {
    var b = ConstRingBuffer(3, u8).init();
    try testing.expect(b.is_empty());
    try b.write(1);
    try testing.expect(!b.is_empty());
    try testing.expect(!b.is_full());
    try b.write(2);
    try b.write(3);
    try testing.expect(b.is_full());
    try testing.expectError(error.Full, b.write(4));
    try testing.expectEqual(1, b.read());
    try b.write(4);
    try testing.expect(b.is_full());
    try testing.expectEqual(2, b.read());
    try testing.expectEqual(3, b.read());
    try testing.expectEqual(4, b.read());
    try testing.expectEqual(null, b.read());
    try testing.expect(b.is_empty());
}

test "ConstRingBuffer push" {
    var b = ConstRingBuffer(3, u8).init();
    try testing.expect(b.is_empty());
    b.push(1);
    try testing.expect(!b.is_full());
    b.push(2);
    try testing.expect(!b.is_full());
    b.push(3);
    try testing.expect(b.is_full());
    b.push(4);
    try testing.expect(b.is_full());
    b.push(5);
    try testing.expect(b.is_full());
    try testing.expectEqual(3, b.read());
    try testing.expectEqual(4, b.read());
    try testing.expectEqual(5, b.read());
    try testing.expect(b.is_empty());
    try testing.expectEqual(null, b.read());
    try testing.expect(b.is_empty());
}

test "ConstRingBuffer capacity" {
    var b = ConstGenericRingBuffer(u8, 255, usize).init();
    try testing.expect(b.is_empty());
    for (0..255) |i| {
        try b.write(i);
    }
    try testing.expect(b.is_full());
    try testing.expectEqual(255, b.len());
    try testing.expectError(error.Full, b.write(0));
    b.push(0);
    try testing.expect(b.is_full());
    try testing.expectEqual(255, b.len());
    for (0..255) |i| {
        try testing.expectEqual((i + 1) % 255, b.read());
    }
    try testing.expect(b.is_empty());
    try testing.expectEqual(null, b.read());
}
