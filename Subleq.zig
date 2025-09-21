// https://rosettacode.org/wiki/Subleq
// {{works with|Zig|0.15.1}}
// {{trans|Kotlin}}
const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const program: []const u8 = "15 17 -1 17 -1 -1 16 1 -1 16 3 -1 15 15 0 0 -1 72 101 108 108 111 44 32 119 111 114 108 100 33 10 0";
    try subleq(allocator, program);
}

fn subleq(allocator: std.mem.Allocator, program: []const u8) !void {
    // ------------------------------------------- output storage
    var sb: std.ArrayList(u8) = .empty;
    defer sb.deinit(allocator);
    // --------------------------------------------- read program
    var word_list: std.ArrayList(i8) = .empty;
    defer word_list.deinit(allocator);

    var it = std.mem.tokenizeScalar(u8, program, ' ');
    while (it.next()) |text|
        try word_list.append(allocator, try std.fmt.parseInt(i8, text, 10));
    const words = try word_list.toOwnedSlice(allocator);
    defer allocator.free(words);
    // --------------------------------------------------- stdout
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    // ------------------------------------------ execute program
    var ip: usize = 0;
    while (true) {
        const a = words[ip];
        const b = words[ip + 1];
        const c = words[ip + 2];
        ip += 3;
        if (a < 0) {
            // Kotlin version input character here from stdin
            // word[b] = char;
            unreachable;
        } else if (b < 0) {
            try sb.append(allocator, @intCast(words[@intCast(a)]));
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
    try stdout.print("{s}\n", .{sb.items});
    try stdout.flush();
}
