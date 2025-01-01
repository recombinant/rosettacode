// https://rosettacode.org/wiki/Subleq
// Translation of Kotlin
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const program: []const u8 = "15 17 -1 17 -1 -1 16 1 -1 16 3 -1 15 15 0 0 -1 72 101 108 108 111 44 32 119 111 114 108 100 33 10 0";
    try subleq(allocator, program);
}

fn subleq(allocator: std.mem.Allocator, program: []const u8) !void {
    // ------------------------------------------- output storage
    var sb = std.ArrayList(u8).init(allocator);
    defer sb.deinit();
    // --------------------------------------------- read program
    var word_list = std.ArrayList(i8).init(allocator);
    defer word_list.deinit();

    var it = std.mem.tokenizeScalar(u8, program, ' ');
    while (it.next()) |text|
        try word_list.append(try std.fmt.parseInt(i8, text, 10));
    const words = try word_list.toOwnedSlice();
    defer allocator.free(words);
    // ------------------------------------------ execute program
    var ip: usize = 0;
    while (true) {
        const a = words[ip];
        const b = words[ip + 1];
        const c = words[ip + 2];
        ip += 3;
        if (a < 0) {
            try std.io.getStdOut().writer().writeAll("Enter a \"character\" : ");
            var buffer: [10]u8 = undefined;
            const len = try std.io.getStdIn().reader().read(&buffer);
            words[@intCast(b)] = try std.fmt.parseInt(i8, buffer[0..len], 10);
        } else if (b < 0) {
            try sb.append(@intCast(words[@intCast(a)]));
        } else {
            words[@intCast(b)] -= words[@intCast(a)];
            if (words[@intCast(b)] <= 0) {
                if (c < 0)
                    break
                else
                    ip = @intCast(c);
            }
        }
    }
    // --------------------------------------------- print output
    try std.io.getStdOut().writer().print("{s}\n", .{sb.items});
}
