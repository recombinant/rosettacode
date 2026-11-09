// https://rosettacode.org/wiki/Szyma%C5%84ski%27s_algorithm
// {{works with|Zig|0.17.1}}
// {{trans|Rust}}
// copied from rosettacode and tweaked
const std = @import("std");
const Io = std.Io;

const Mutex = Io.Mutex;
const Allocator = std.mem.Allocator;
const HashMap = std.AutoHashMap;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    const allocator: Allocator = init.arena.allocator();

    try testSzymanski(io, allocator, 20);
}

fn testSzymanski(io: Io, allocator: Allocator, n: i32) !void {
    // Create array of "thread" IDs
    var all_szy = allocator.alloc(i32, @intCast(n)) catch @panic("OOM");
    for (0..@intCast(n)) |i|
        all_szy[i] = @intCast(i + 1);

    var flags_state = allocator.create(FlagsState) catch @panic("OOM");
    flags_state.* = .init(allocator);
    defer flags_state.deinit();

    const critical_value = allocator.create(SharedInt) catch @panic("OOM");
    critical_value.* = .init(1);

    const shared_state: SharedState = .{
        .all_szy = all_szy,
        .flags_state = flags_state,
        .critical_value = critical_value,
    };

    var group: Io.Group = .init;
    for (0..@intCast(n)) |i| {
        const id: i32 = @intCast(i + 1);
        try group.concurrent(io, runSzymanski, .{ io, allocator, id, shared_state });
    }
    errdefer group.cancel(io);
    try group.await(io);
}

fn runSzymanski(io: Io, allocator: Allocator, id: i32, shared_state: SharedState) error{Canceled}!void {
    var others: std.ArrayList(i32) = .empty;
    defer others.deinit(allocator);

    others.ensureTotalCapacityPrecise(allocator, shared_state.all_szy.len - 1) catch @panic("OOM");
    // Filter for others
    for (shared_state.all_szy) |other_id|
        if (other_id != id)
            others.append(allocator, other_id) catch @panic("OOM");

    // Standing outside waiting room
    {
        try shared_state.flags_state.mutex.lock(io);
        defer shared_state.flags_state.mutex.unlock(io);

        shared_state.flags_state.flags.put(id, .waiting_room) catch @panic("OOM");
    }

    // Wait until no other process is in or passing through the doorway
    while (true) {
        var should_wait = false;

        try shared_state.flags_state.mutex.lock(io);
        for (others.items) |other_id|
            if (shared_state.flags_state.flags.get(other_id)) |flag|
                if (@backingInt(flag) >= @backingInt(State.doorway)) {
                    should_wait = true;
                    break;
                };
        shared_state.flags_state.mutex.unlock(io);

        if (!should_wait)
            break;
        try Io.sleep(io, .fromSeconds(1), .real); // yield
    }

    // Standing in doorway
    {
        try shared_state.flags_state.mutex.lock(io);
        defer shared_state.flags_state.mutex.unlock(io);

        shared_state.flags_state.flags.put(id, .doorway) catch @panic("OOM");
    }

    // Check if other processes are still waiting
    var others_waiting = false;
    {
        try shared_state.flags_state.mutex.lock(io);
        defer shared_state.flags_state.mutex.unlock(io);

        for (others.items) |other_id|
            if (shared_state.flags_state.flags.get(other_id)) |flag|
                if (flag == .waiting_room) {
                    others_waiting = true;
                    break;
                };
    }

    if (others_waiting) {
        // Waiting for other processes to enter
        {
            try shared_state.flags_state.mutex.lock(io);
            defer shared_state.flags_state.mutex.unlock(io);

            shared_state.flags_state.flags.put(id, .waiting_for_others) catch @panic("OOM");
        }

        // Wait for other processes to close the door
        while (true) {
            var should_continue = true;

            try shared_state.flags_state.mutex.lock(io);
            for (others.items) |other_id|
                if (shared_state.flags_state.flags.get(other_id)) |flag|
                    if (flag == .in_critical_section) {
                        should_continue = false;
                        break;
                    };
            shared_state.flags_state.mutex.unlock(io);

            if (!should_continue)
                break;
            try Io.sleep(io, .fromSeconds(1), .real); // yield
        }
    }

    // The door is closed
    {
        try shared_state.flags_state.mutex.lock(io);
        defer shared_state.flags_state.mutex.unlock(io);

        shared_state.flags_state.flags.put(id, .in_critical_section) catch @panic("OOM");
    }

    // Wait for lower numbered processes
    for (others.items) |other_id| {
        if (other_id >= id)
            continue;

        while (true) {
            var should_wait = false;

            try shared_state.flags_state.mutex.lock(io);
            if (shared_state.flags_state.flags.get(other_id)) |flag|
                if (@backingInt(flag) > @backingInt(State.waiting_room)) {
                    should_wait = true;
                };
            shared_state.flags_state.mutex.unlock(io);

            if (!should_wait)
                break;
            try Io.sleep(io, .fromSeconds(1), .real); // yield
        }
    }

    // Critical section
    {
        try shared_state.critical_value.mutex.lock(io);
        defer shared_state.critical_value.mutex.unlock(io);

        shared_state.critical_value.value += id * 3;
        shared_state.critical_value.value = @divTrunc(shared_state.critical_value.value, 2);
        std.debug.print("Thread {} changed the critical value to {}.\n", .{ id, shared_state.critical_value.value });
    }

    // Exit protocol
    for (others.items) |other_id| {
        if (other_id <= id)
            continue;

        while (true) {
            var should_wait = true;

            try shared_state.flags_state.mutex.lock(io);
            if (shared_state.flags_state.flags.get(other_id)) |flag|
                if (flag == .outside or flag == .waiting_room or flag == .in_critical_section) {
                    should_wait = false;
                };
            shared_state.flags_state.mutex.unlock(io);

            if (!should_wait)
                break;
            try Io.sleep(io, .fromSeconds(1), .real); // yield
        }
    }

    // Leave
    {
        try shared_state.flags_state.mutex.lock(io);
        defer shared_state.flags_state.mutex.unlock(io);

        shared_state.flags_state.flags.put(id, .outside) catch @panic("OOM");
    }
}

// Define constants for state representation
const State = enum(i32) {
    outside = 0,
    waiting_room = 1,
    waiting_for_others = 2,
    doorway = 3,
    in_critical_section = 4,
};

const FlagsState = struct {
    mutex: Mutex,
    flags: HashMap(i32, State),

    fn init(allocator: Allocator) FlagsState {
        return .{
            .mutex = .init,
            .flags = .init(allocator),
        };
    }

    fn deinit(self: *FlagsState) void {
        self.flags.deinit();
    }
};

const SharedState = struct {
    all_szy: []const i32,
    flags_state: *FlagsState,
    critical_value: *SharedInt,
};

const SharedInt = struct {
    mutex: Mutex,
    value: i32,

    fn init(value: i32) SharedInt {
        return .{
            .mutex = .init,
            .value = value,
        };
    }
};
