// https://rosettacode.org/wiki/Resistance_calculator
// {{works with|Zig|0.15.1}}

// Infix
const std = @import("std");
const _shared_ = @import("Resistance_calculator-shared_code.zig");

const Allocator = std.mem.Allocator;
const StackUnmanaged = _shared_.StackUnmanaged;
const Node = _shared_.Node;
const PostfixToken = _shared_.PostfixToken;
const calculate = _shared_.calculate;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const node = try infix(allocator, stdout, 18, "((((10+2)*6+8)*6+4)*8+4)*8+6");

    std.debug.assert(10 == node.res());
    std.debug.assert(18 == node.voltage);
    std.debug.assert(1.8 == node.current());
    std.debug.assert(@abs(32.4 - node.effect()) < 0.05);
    std.debug.assert(.serial == node.node_type);

    node.destroyDescendants(allocator);
    allocator.destroy(node);
}

// Zig tagged union.
const InfixToken = union(enum) {
    lparen,
    rparen,
    serial, // +
    parallel, // *

    // Slice of digits from parent string.
    // Do not let the parent string go out of scope while this is in scope.
    resistor: []const u8,
};

/// Convert infix expression 's' to postfix and call the postfix calculate()
fn infix(allocator: Allocator, w: *std.Io.Writer, voltage: f32, s: []const u8) !*Node {
    // parse infix expression
    const infix_tokens: []InfixToken = try parse(allocator, s);
    defer allocator.free(infix_tokens);

    // convert infix to postfix
    const postfix_tokens: []PostfixToken = try shuntPostfix(allocator, infix_tokens);
    defer allocator.free(postfix_tokens);

    // use postfix calculate()
    return try calculate(allocator, w, voltage, postfix_tokens);
}

const InfixParseError = error{
    UnexpectedCharacter,
};

/// Parse infix expression 's' to give a slice of InfixToken.
/// Caller owns slice memory on return.
/// There are no Zig language semantics to indicate ownership or transferal thereof.
fn parse(allocator: Allocator, s: []const u8) ![]InfixToken {
    var tokens: std.ArrayList(InfixToken) = .empty;
    // defer tokens.deinit(); // not needed, toOwnedSlice() owns memory.

    var slice_start: ?usize = null;

    for (s, 0..) |ch, i| {
        const token: InfixToken = switch (ch) {
            '(' => InfixToken.lparen,
            ')' => InfixToken.rparen,
            '+' => InfixToken.serial,
            '*' => InfixToken.parallel,
            '0'...'9' => {
                // Add digits to 'resistor' value.
                // 'slice_start' determines if any digit(s) have already been parsed.
                if (slice_start) |_| _ = tokens.pop() else slice_start = i;
                const slice_end = i + 1;
                try tokens.append(allocator, InfixToken{ .resistor = s[slice_start.?..slice_end] });
                continue;
            },
            ' ', '\t' => { // extraneous whitespace
                slice_start = null;
                continue;
            },
            else => return InfixParseError.UnexpectedCharacter, // unknown
        };
        try tokens.append(allocator, token);
        // Last token was not a resistor. Reset 'start_slice'.
        slice_start = null;
    }
    return tokens.toOwnedSlice(allocator);
}

const ShuntPostfixError = error{
    LParenNotAllowed,
    RParenNotAllowed,
};

/// Input infix (infix tokens) in infix order.
/// Output postfix (postfix tokens) in postfix order.
///
/// Caller owns resultant slice and is responsible for freeing.
fn shuntPostfix(allocator: Allocator, infix_tokens: []InfixToken) ![]PostfixToken {
    var result: PostfixTokenArray = .empty; // destination storage
    var stack: InfixTokenStack = .empty; // working storage
    defer result.deinit(allocator);
    defer stack.deinit(allocator);

    for (infix_tokens) |token| {
        switch (token) {
            .lparen => try stack.push(allocator, token),
            .rparen => while (!stack.isEmpty()) {
                const op = stack.pop();
                if (op == InfixToken.lparen) break;
                try result.append(allocator, op);
            },
            .parallel, .serial => {
                while (!stack.isEmpty()) {
                    const op = stack.peek();
                    if (op != InfixToken.serial and op != InfixToken.parallel) break;
                    _ = stack.pop();
                    try result.append(allocator, op);
                }
                try stack.push(allocator, token);
            },
            .resistor => try result.append(allocator, token),
        }
    }
    while (!stack.isEmpty())
        try result.append(allocator, stack.pop());

    // array now contains operands and operators in postfix order (no parentheses)
    return result.toOwnedSlice(allocator);
}

const InfixTokenStack = StackUnmanaged(InfixToken);

/// Façade to an ArrayList that translates from InfixToken tagged unions to
/// PostfixToken tagged unions in its append() function.
const PostfixTokenArray = struct {
    result: std.ArrayList(PostfixToken),

    const empty: PostfixTokenArray = .{
        .result = .empty,
    };
    fn deinit(self: *PostfixTokenArray, allocator: std.mem.Allocator) void {
        self.result.deinit(allocator);
    }
    /// Convert InfixToken to PostfixToken.
    fn append(self: *PostfixTokenArray, allocator: std.mem.Allocator, infix_token: InfixToken) !void {
        const postfix_token: PostfixToken = switch (infix_token) {
            .serial => PostfixToken.serial,
            .parallel => PostfixToken.parallel,
            .resistor => |slice| PostfixToken{ .resistor = slice },

            // Postfix does not have parentheses.
            .lparen => return ShuntPostfixError.LParenNotAllowed,
            .rparen => return ShuntPostfixError.RParenNotAllowed,
        };
        try self.result.append(allocator, postfix_token);
    }
    fn toOwnedSlice(self: *PostfixTokenArray, allocator: Allocator) !std.ArrayList(PostfixToken).Slice {
        return try self.result.toOwnedSlice(allocator);
    }
};
