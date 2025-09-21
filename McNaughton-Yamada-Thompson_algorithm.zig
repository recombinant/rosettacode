// https://rosettacode.org/wiki/McNaughton-Yamada-Thompson_algorithm
// {{works with|Zig|0.15.1}}
// {{trans|C++}}

// This is a nearly verbatim translation of the C++ solution
// with the use of a memory pool for State creation.
const std = @import("std");
const mem = std.mem;

pub fn main() !void {
    // ------------------------------------------------ allocator
    // https://ziglang.org/documentation/master/std/#std.heap.ArenaAllocator
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var state_pool: StatePool = .init(std.heap.page_allocator);
    defer state_pool.deinit();
    // ----------------------------------------------------------
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const infixes = [_][]const u8{ "a.b.c*", "a.(b|d).c*", "(a.(b|d))*", "a.(b.b)*.c" };
    const strings = [_][]const u8{ "", "abc", "abbc", "abcc", "abad", "abbbc" };

    for (infixes) |infix| {
        for (strings) |str| {
            const result = try matchRegex(allocator, &state_pool, infix, str);
            _ = arena.reset(.retain_capacity); // reset allocated memory
            _ = state_pool.reset(.retain_capacity);
            try stdout.print("{} {s} {s}\n", .{ result, infix, str });
        }
        try stdout.writeByte('\n');
    }
    try stdout.flush();
}

// Function to match a string against the regex
fn matchRegex(allocator: mem.Allocator, state_pool: *StatePool, infix: []const u8, str: []const u8) !bool {
    const postfix = try shunt(allocator, infix);
    // Uncomment the next line to see the postfix expression
    // std.debug.print("Postfix: {s}\n", .{postfix});

    const nfa = try compileRegex(allocator, state_pool, postfix);

    var current: StateSet = try followes(allocator, nfa.initial.?);
    var nextStates: StateSet = .empty;

    for (str) |c| {
        for (current.keys()) |state|
            if (state.label == c) {
                const follow = try followes(allocator, state.edge1.?);
                for (follow.keys()) |state2|
                    try nextStates.put(allocator, state2, {});
            };
        current = nextStates;
        nextStates.clearRetainingCapacity();
    }
    return current.contains(nfa.accept.?);
}

/// Function to convert infix regex to postfix using the Shunting Yard algorithm.
/// Caller owns returned slice memory.
fn shunt(allocator: mem.Allocator, infix: []const u8) ![]const u8 {
    var specials = blk: {
        const specialsK = [_]u8{ '*', '+', '?', '.', '|' };
        const specialsV = [specialsK.len]u8{ 60, 55, 50, 40, 20 };

        var specials: std.AutoArrayHashMapUnmanaged(u8, u8) = .empty;
        for (specialsK, specialsV) |k, v|
            try specials.put(allocator, k, v);
        break :blk specials;
    };
    var postfix: std.ArrayList(u8) = .empty;
    var stack: Stack(u8) = .empty;

    for (infix) |c| {
        if (c == '(')
            try stack.push(allocator, c)
        else if (c == ')') {
            while (!stack.isEmpty() and stack.top() != '(')
                try postfix.append(allocator, stack.pop());
            if (!stack.isEmpty())
                _ = stack.pop(); // Remove '('
        } else if (specials.contains(c)) {
            while (!stack.isEmpty() and specials.contains(stack.top()) and specials.get(c).? <= specials.get(stack.top()).?)
                try postfix.append(allocator, stack.pop());
            try stack.push(allocator, c);
        } else {
            try postfix.append(allocator, c);
        }
    }
    while (!stack.isEmpty())
        try postfix.append(allocator, stack.pop());
    return postfix.toOwnedSlice(allocator);
}

const StatePool = std.heap.MemoryPoolExtra(State, .{});
const StateSet = std.AutoArrayHashMapUnmanaged(*State, void);

const State = struct {
    label: u8 = 0, // Character label, '\0' for epsilon
    edge1: ?*State = null, // First transition
    edge2: ?*State = null, // Second transition

    fn init(label: u8) State {
        return .{ .label = label };
    }
};

const NFA = struct {
    initial: ?*State,
    accept: ?*State,

    fn init(initial: ?*State, accept: ?*State) NFA {
        return .{ .initial = initial, .accept = accept };
    }
};

/// Function to compute the epsilon closure of a state
fn followes(allocator: mem.Allocator, state: *State) !StateSet {
    var states: StateSet = .empty;
    var stack: Stack(*State) = .empty;
    try stack.push(allocator, state);
    while (!stack.isEmpty()) {
        const s = stack.pop();
        if (!states.contains(s)) {
            try states.put(allocator, s, {});
            if (s.label == 0) { // Epsilon transition
                if (s.edge1) |edge1| try stack.push(allocator, edge1);
                if (s.edge2) |edge2| try stack.push(allocator, edge2);
            }
        }
    }
    return states;
}

// Function to compile postfix regex into an NFA
fn compileRegex(allocator: mem.Allocator, state_pool: *StatePool, postfix: []const u8) !NFA {
    var nfa_stack: Stack(NFA) = .empty;

    for (postfix) |c| {
        switch (c) {
            '*' => {
                var nfa1 = nfa_stack.pop();
                var initial = try state_pool.create();
                const accept = try state_pool.create();
                initial.* = State{};
                accept.* = State{};
                initial.edge1 = nfa1.initial;
                initial.edge2 = accept;
                nfa1.accept.?.edge1 = nfa1.initial;
                nfa1.accept.?.edge2 = accept;
                try nfa_stack.push(allocator, .init(initial, accept));
            },
            '.' => {
                const nfa2 = nfa_stack.pop();
                const nfa1 = nfa_stack.pop();
                nfa1.accept.?.edge1 = nfa2.initial;
                try nfa_stack.push(allocator, .init(nfa1.initial, nfa2.accept));
            },
            '|' => {
                const nfa2 = nfa_stack.pop();
                const nfa1 = nfa_stack.pop();
                var initial = try state_pool.create();
                const accept = try state_pool.create();
                initial.* = State{};
                accept.* = State{};
                initial.edge1 = nfa1.initial;
                initial.edge2 = nfa2.initial;
                nfa1.accept.?.edge1 = accept;
                nfa2.accept.?.edge1 = accept;
                try nfa_stack.push(allocator, .init(initial, accept));
            },
            '+' => {
                const nfa1 = nfa_stack.pop();
                var initial = try state_pool.create();
                const accept = try state_pool.create();
                initial.* = State{};
                accept.* = State{};
                initial.edge1 = nfa1.initial;
                nfa1.accept.?.edge1 = nfa1.initial;
                nfa1.accept.?.edge2 = accept;
                try nfa_stack.push(allocator, .init(initial, accept));
            },
            '?' => {
                const nfa1 = nfa_stack.pop();
                var initial = try state_pool.create();
                const accept = try state_pool.create();
                initial.* = State{};
                accept.* = State{};
                initial.edge1 = nfa1.initial;
                initial.edge2 = accept;
                nfa1.accept.?.edge1 = accept;
                try nfa_stack.push(allocator, .init(initial, accept));
            },
            else => {
                // Literal character
                var initial = try state_pool.create();
                const accept = try state_pool.create();
                initial.* = .init(c);
                accept.* = .{};
                initial.edge1 = accept;
                try nfa_stack.push(allocator, .init(initial, accept));
            },
        }
    }
    return nfa_stack.pop();
}

// An ad hoc generic stack implementation.
fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();
        stack: std.ArrayList(T),

        const empty = Self{
            .stack = .empty,
        };
        fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.stack.deinit(allocator);
        }
        fn push(self: *Self, allocator: std.mem.Allocator, node: T) !void {
            return try self.stack.append(allocator, node);
        }
        fn pop(self: *Self) T {
            return self.stack.pop().?;
        }
        fn top(self: *const Self) T {
            return self.stack.items[self.stack.items.len - 1];
        }
        fn isEmpty(self: *const Self) bool {
            return self.stack.items.len == 0;
        }
    };
}
