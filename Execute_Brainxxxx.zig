// https://rosettacode.org/wiki/Execute_Brain****
const std = @import("std");

const IrNode = union(enum) {
    Addp: usize,
    Subp: usize,
    Add: u8,
    Sub: u8,
    Write,
    Read,
    Jz: usize,
    Jnz: usize,
};

// - Precomputes branch jump points.
// - Fuses adjacent instructions of same type.
fn compileBrainfuck(allocator: std.mem.Allocator, program: []const u8) ![]IrNode {
    var jump_stack = std.ArrayList(usize).init(allocator);
    defer jump_stack.deinit();

    var nodes = std.ArrayList(IrNode).init(allocator);
    errdefer nodes.deinit();

    var i: usize = 0;
    while (i < program.len) : (i += 1) {
        switch (program[i]) {
            '>' => {
                var c: usize = 1;
                while (i + 1 < program.len and program[i + 1] == '>') : (i += 1)
                    c += 1;
                try nodes.append(IrNode{ .Addp = c });
            },
            '<' => {
                var c: usize = 1;
                while (i + 1 < program.len and program[i + 1] == '<') : (i += 1)
                    c += 1;
                try nodes.append(IrNode{ .Subp = c });
            },
            '+' => {
                var c: u8 = 1;
                while (i + 1 < program.len and program[i + 1] == '+') : (i += 1)
                    c +%= 1;
                try nodes.append(IrNode{ .Add = c });
            },
            '-' => {
                var c: u8 = 1;
                while (i + 1 < program.len and program[i + 1] == '-') : (i += 1)
                    c +%= 1;
                try nodes.append(IrNode{ .Sub = c });
            },
            '.' => try nodes.append(IrNode.Write),
            ',' => try nodes.append(IrNode.Read),
            '[' => {
                try jump_stack.append(nodes.items.len);
                try nodes.append(IrNode{ .Jz = undefined });
            },
            ']' => {
                const entry = jump_stack.popOrNull() orelse return error.UnmatchedBrackets;
                try nodes.append(IrNode{ .Jnz = entry });
                nodes.items[entry].Jz = nodes.items.len - 1;
            },
            else => {},
        }
    }

    if (jump_stack.items.len != 0)
        return error.UnmatchedBrackets;

    return nodes.toOwnedSlice();
}

fn executeBrainfuck(
    comptime tape_length: usize,
    allocator: std.mem.Allocator,
    writer: anytype,
    program: []const u8,
) !void {
    var memory = [1]u8{0} ** tape_length;
    var mp: usize = 0;
    var pc: usize = 0;

    const bytecode = try compileBrainfuck(allocator, program);
    defer allocator.free(bytecode);

    while (pc < bytecode.len) : (pc += 1) {
        switch (bytecode[pc]) {
            IrNode.Addp => |c| mp = (mp + c) % memory.len,
            IrNode.Subp => |c| mp = (mp + memory.len - c) % memory.len,
            IrNode.Add => |c| memory[mp] +%= c,
            IrNode.Sub => |c| memory[mp] -%= c,
            IrNode.Write => try writer.print("{c}", .{memory[mp]}),
            IrNode.Read => unreachable,
            // {
            //     memory[mp] = reader.readByte() catch |err| switch (err) {
            //         error.EndOfStream => return,
            //         else => return err,
            //     };
            // },
            IrNode.Jz => |c| {
                if (memory[mp] == 0)
                    pc = c;
            },
            IrNode.Jnz => |c| {
                if (memory[mp] != 0)
                    pc = c;
            },
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    const hello_world_program =
        \\>++++++++[<+++++++++>-]<.>>+>+>++>[-]+<[>[->+<<++++>]<<]>.+++++++..+++.>
        \\>+++++++.<<<[[-]<[-]>]<+++++++++++++++.>>.+++.------.--------.>>+.>++++.
    ;

    try executeBrainfuck(30000, allocator, stdout, hello_world_program);
}
