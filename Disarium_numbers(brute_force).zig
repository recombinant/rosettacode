// https://rosettacode.org/wiki/Disarium_numbers
// {{works with|Zig|0.17.1}}
// {{trans|C}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_file.interface;

    // ----------------------------------------------------------
    try stdout.writeAll("The first 19 Disarium numbers (simple)\n");

    var count: usize = 0;
    var i: usize = 0;
    while (count < 19) : (i += 1)
        if (isDisarium(u32, @intCast(i))) {
            if (count != 0)
                try stdout.writeByte(' ');
            try stdout.print("{}", .{i});
            count += 1;
        };
    try stdout.writeByte('\n');
    // ----------------------------------------------------------
    try stdout.flush();
}

fn isDisarium(T: type, num: T) bool {
    if (@typeInfo(T) != .int or @typeInfo(T).int.signedness != .unsigned)
        @compileError("isDisarium() expected unsigned integer argument, found " ++ @typeName(T));
    var n = num;
    var sum: T = 0;
    var len = if (n <= 9) 1 else std.math.log_int(T, 10, n) + 1;
    while (n > 0) {
        sum += std.math.pow(T, n % 10, len);
        n /= 10;
        len -= 1;
    }
    return num == sum;
}

const testing = std.testing;

test isDisarium {
    try testing.expect(isDisarium(u32, 0));
    try testing.expect(isDisarium(u32, 89));
    try testing.expect(isDisarium(u32, 135));
    try testing.expect(isDisarium(u64, 12_157_692_622_039_623_539));

    try testing.expect(!isDisarium(u32, 10));
    try testing.expect(!isDisarium(u32, 88));
    try testing.expect(!isDisarium(u32, 136));
}
