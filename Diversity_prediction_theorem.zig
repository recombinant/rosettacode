// https://rosettacode.org/wiki/Diversity_prediction_theorem
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const predsArray = [2][]const f64{
        &[_]f64{ 48, 47, 51 },
        &[_]f64{ 48, 47, 51, 42 },
    };
    const truth: f64 = 49.0;
    for (predsArray) |preds| {
        const avErr, const crowdErr, const div = diversityTheorem(truth, preds);
        print("Average-error : {d:6.3}\n", .{avErr});
        print("Crowd-error   : {d:6.3}\n", .{crowdErr});
        print("Diversity     : {d:6.3}\n\n", .{div});
    }
}

fn averageSquareDiff(f: f64, preds: []const f64) f64 {
    var avg: f64 = 0;
    for (preds) |pred|
        avg += (pred - f) * (pred - f);
    avg /= @floatFromInt(preds.len);

    return avg;
}

fn diversityTheorem(truth: f64, preds: []const f64) struct { f64, f64, f64 } {
    var avg: f64 = 0.0;
    for (preds) |pred|
        avg += pred;
    avg /= @floatFromInt(preds.len);

    const avErr = averageSquareDiff(truth, preds);
    const crowdErr = (truth - avg) * (truth - avg);
    const div = averageSquareDiff(avg, preds);
    return .{ avErr, crowdErr, div };
}
