// https://rosettacode.org/wiki/Simulated_annealing
// {{works with|Zig|0.17.1}}
// {{trans|Rust}}
// copied from rosettacode and tweaked
const std = @import("std");
const Io = std.Io;
const print = std.debug.print;

const NUM_CITIES: usize = 100;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var sa = SA.new(io);
    _ = sa.run(); // Run simulated annealing and log progress and result

    print("Press Enter to exit...\n", .{});

    var stdin_buffer: [256]u8 = undefined;
    var stdin_file = Io.File.stdin().reader(io, stdin_buffer[0..]);
    var stdin_reader: *Io.Reader = &stdin_file.interface;

    var buffer: [256]u8 = undefined;
    var fw: Io.Writer = .fixed(buffer[0..]);

    _ = try stdin_reader.streamDelimiter(&fw, '\n');
}

const Coord = struct { x: i32, y: i32 };

// CityID with member functions to get position
const CityID = struct {
    v: u32,

    const Self = @This();

    fn fromInt(i: u32) Self {
        return .{ .v = i };
    }

    fn fromCoord(pos: Coord) !Self {
        if (pos.x < 0 or pos.x > 9 or pos.y < 0 or pos.y > 9)
            return error.InvalidCoordinates;

        return .{ .v = @intCast(pos.x * 10 + pos.y) };
    }

    fn getPos(self: Self) Coord {
        return .{ .x = @intCast(self.v / 10), .y = @intCast(self.v % 10) };
    }

    /// Function for distance between two cities
    fn distance(self: Self, other: Self) f64 {
        const city1 = self.getPos();
        const city2 = other.getPos();
        const delta_x: f64 = @floatFromInt(city1.x - city2.x);
        const delta_y: f64 = @floatFromInt(city1.y - city2.y);
        return std.math.hypot(delta_x, delta_y);
    }
};

// Function for total distance travelled
fn distCities(cities: []const CityID) f64 {
    var sum: f64 = 0.0;
    for (0..cities.len - 1) |i|
        sum += cities[i].distance(cities[i + 1]);

    sum += cities[cities.len - 1].distance(cities[0]);
    return sum;
}

// 8 nearest cities, id cannot be at the border and has to have 8 valid neighbors
fn getNearest(id: CityID) [8]CityID {
    const pos = id.getPos();
    const i = pos.x;
    const j = pos.y;
    return .{
        CityID.fromCoord(.{ .x = i - 1, .y = j - 1 }) catch unreachable,
        CityID.fromCoord(.{ .x = i, .y = j - 1 }) catch unreachable,
        CityID.fromCoord(.{ .x = i + 1, .y = j - 1 }) catch unreachable,
        CityID.fromCoord(.{ .x = i - 1, .y = j }) catch unreachable,
        CityID.fromCoord(.{ .x = i + 1, .y = j }) catch unreachable,
        CityID.fromCoord(.{ .x = i - 1, .y = j + 1 }) catch unreachable,
        CityID.fromCoord(.{ .x = i, .y = j + 1 }) catch unreachable,
        CityID.fromCoord(.{ .x = i + 1, .y = j + 1 }) catch unreachable,
    };
}

const SA = struct {
    k_t: i32,
    k_max: i32,
    s: [NUM_CITIES]CityID,
    random: std.Random,

    const Self = @This();

    fn new(io: Io) Self {
        var s: [NUM_CITIES]CityID = undefined;
        // Initialize state with integers from 0..NUM_CITIES
        for (s[0..], 0..) |*city, i|
            city.* = .fromInt(@intCast(i));

        var prng: std.Random.DefaultPrng = .init(blk: {
            var seed: u64 = undefined;
            Io.random(io, std.mem.asBytes(&seed));
            break :blk seed;
        });
        const random = prng.random();

        random.shuffle(CityID, s[0..]);

        return .{
            .k_t = 1,
            .k_max = 1_000_000,
            .s = s,
            .random = random,
        };
    }

    // Temperature
    fn temperature(self: Self, k: i32) f64 {
        return @as(f64, @floatFromInt(self.k_t)) * (1.0 - @as(f64, @floatFromInt(k)) / @as(f64, @floatFromInt(self.k_max)));
    }

    // Probability of acceptance between 0.0 and 1.0
    fn probability(d_e: f64, t: f64) f64 {
        return if (d_e < 0.0)
            1.0
        else
            @exp(-d_e / t);
    }

    // Permutation of state through swapping of cities in travel path
    fn nextPermut(self: *Self, cities: [NUM_CITIES]CityID) [NUM_CITIES]CityID {
        var result = cities;

        const rand_city = CityID.fromCoord(Coord{
            .x = self.random.intRangeAtMost(i32, 1, 8),
            .y = self.random.intRangeAtMost(i32, 1, 8),
        }) catch unreachable;

        const neighbors = getNearest(rand_city);
        const rand_neighbor = neighbors[self.random.intRangeAtMost(usize, 0, neighbors.len - 1)];

        // Find selected city in state
        var city_pos1: usize = 0;
        var city_pos2: usize = 0;

        for (result[0..], 0..) |city, i| {
            if (city.v == rand_city.v) city_pos1 = i;
            if (city.v == rand_neighbor.v) city_pos2 = i;
        }

        // Swap city and neighbor
        std.mem.swap(CityID, &result[city_pos1], &result[city_pos2]);
        return result;
    }

    // Logging function for progress output
    fn logProgress(self: Self, k: i32, t: f64, e: f64) void {
        const n_digits = std.math.log10_int(@as(u32, @intCast(self.k_max))) + 1;
        // Cast to unsigned to remove unnecessary + sign.
        print("k: {d:>7} | T: {d:.3} | E(s): {d:.4}\n", .{ @as(u32, @intCast(k)), t, e });
        _ = n_digits; // unused in this simplified version
    }

    // Logging function for final path
    fn logPath(self: Self) void {
        for (self.s[0..], 0..) |city, idx| {
            print("{d:2} -> ", .{city.v});
            if ((idx + 1) % 20 == 0)
                print("\n", .{});
        }
        print("{d:2}\n", .{self.s[0].v});
    }

    // Core simulated annealing algorithm
    fn run(self: *Self) [NUM_CITIES]CityID {
        print("kT == {d}\n", .{self.k_t});
        print("kmax == {d}\n", .{self.k_max});
        print("E(s0) == {d}\n", .{distCities(&self.s)});

        for (0..@intCast(self.k_max)) |k_usize| {
            const k: i32 = @intCast(k_usize);
            const t = self.temperature(k);
            const e1 = distCities(&self.s);
            const s_next = self.nextPermut(self.s);
            const e2 = distCities(&s_next);
            const d_e = e2 - e1; // lower is better

            if (probability(d_e, t) >= self.random.float(f64))
                self.s = s_next;

            if (@mod(k, 100000) == 0)
                self.logProgress(k, t, e1);
        }

        self.logProgress(self.k_max, 0.0, distCities(&self.s));
        print("\nFinal path:\n", .{});
        self.logPath();
        return self.s;
    }
};
