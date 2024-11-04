const std = @import("std");

pub const default_allocator = std.heap.c_allocator;

test {
    std.testing.refAllDecls(@This());
}
