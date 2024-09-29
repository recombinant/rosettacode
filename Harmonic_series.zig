// https://www.rosettacode.org/wiki/Harmonic_series
const std = @import("std");
const math = std.math;
const mem = std.mem;
const Rational = math.big.Rational;
const Int = math.big.Managed;

pub fn main() !void {
    // ------------------------------------------------------- stdout
    const stdout = std.io.getStdOut().writer();
    // ---------------------------------------------------- allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    // ---------------------------------------- alternative allocator
    //   var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //   defer _ = gpa.deinit();
    //
    //   const allocator = gpa.allocator();
    // --------------------------------------------------------------
    var t0 = try std.time.Timer.start();
    // --------------------------------------------------------------
    var hgen = try HarmonicGenerator.init(allocator);
    defer hgen.deinit();

    try stdout.writeAll("First 20 harmonic numbers:\n");
    while (hgen.n < 20) {
        var h: Harmonic = try hgen.next();
        defer h.deinit();
        try stdout.print("{d:3}. {}/{}\n", .{ h.n, h.term.p, h.term.q });
    }
    try stdout.writeByte('\n');
    // ------------
    try stdout.writeAll("100th harmonic number:\n");
    {
        while (hgen.n < 99) {
            var h = try hgen.next();
            defer h.deinit();
        }
        var h: Harmonic = try hgen.next();
        defer h.deinit();
        try stdout.print("{}/{}\n", .{ h.term.p, h.term.q });
    }
    try stdout.writeByte('\n');
    // ------------
    try hgen.reset();
    for (1..11) |n| {
        const r: f32 = @floatFromInt(n);
        while (true) {
            var h: Harmonic = try hgen.next();
            defer h.deinit();
            if (try h.term.toFloat(f32) > r) {
                try stdout.print("Position of first term > {d:2}: {d}\n", .{ n, h.n });
                break;
            }
        }
    }
    try stdout.writeByte('\n');
    // --------------------------------------------------------------
    try stdout.print("Processed in {}", .{std.fmt.fmtDuration(t0.read())});
}

const Harmonic = struct {
    n: usize,
    term: Rational,

    fn deinit(self: *Harmonic) void {
        self.term.deinit();
    }
};

const HarmonicGenerator = struct {
    n: usize,
    term: Rational,
    reciprocal: Rational,
    allocator: mem.Allocator,

    fn init(allocator: mem.Allocator) !HarmonicGenerator {
        return .{
            .n = 0,
            .term = try Rational.init(allocator), // {.p=0,.q=1}
            .allocator = allocator,
            .reciprocal = try Rational.init(allocator),
        };
    }

    fn deinit(self: *HarmonicGenerator) void {
        self.term.deinit();
        self.reciprocal.deinit();
    }

    fn reset(self: *HarmonicGenerator) !void {
        self.n = 0;
        try self.term.setRatio(0, 1);
    }

    fn next(self: *HarmonicGenerator) !Harmonic {
        self.n += 1;
        try self.reciprocal.setRatio(1, self.n);

        var rma = try Rational.init(self.allocator);
        try rma.add(self.term, self.reciprocal);

        try self.term.copyRatio(rma.p, rma.q);

        return Harmonic{
            .n = self.n,
            .term = rma,
        };
    }
};
