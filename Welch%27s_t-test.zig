// https://rosettacode.org/wiki/Welch%27s_t-test
// {{works with|Zig|0.15.1}}
// {{trans|C}}

// Refer to C code for comments and license
const std = @import("std");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    const d1 = [15]f64{ 27.5, 21.0, 19.0, 23.6, 17.0, 17.9, 16.9, 20.1, 21.9, 22.6, 23.1, 19.6, 19.0, 21.7, 21.4 };
    const d2 = [15]f64{ 27.1, 22.0, 20.8, 23.4, 23.4, 23.5, 25.8, 22.0, 24.8, 20.2, 21.9, 22.1, 22.9, 20.5, 24.4 };
    const d3 = [10]f64{ 17.2, 20.9, 22.6, 18.1, 21.7, 21.4, 23.5, 24.2, 14.7, 21.8 };
    const d4 = [20]f64{ 21.5, 22.8, 21.0, 23.0, 21.6, 23.6, 22.5, 20.7, 23.4, 21.8, 20.7, 21.7, 21.5, 22.5, 23.6, 21.5, 22.5, 23.5, 21.5, 21.8 };
    const d5 = [10]f64{ 19.8, 20.4, 19.6, 17.8, 18.5, 18.9, 18.3, 18.9, 19.5, 22.0 };
    const d6 = [20]f64{ 28.2, 26.6, 20.1, 23.3, 25.2, 22.1, 17.7, 27.6, 20.6, 13.7, 23.2, 17.5, 20.6, 18.0, 23.9, 21.6, 24.3, 20.4, 24.0, 13.2 };
    const d7 = [6]f64{ 30.02, 29.99, 30.11, 29.97, 30.01, 29.99 };
    const d8 = [6]f64{ 29.89, 29.93, 29.72, 29.98, 30.02, 29.98 };
    const x = [4]f64{ 3.0, 4.0, 1.0, 2.1 };
    const y = [3]f64{ 490.2, 340.0, 433.9 };
    const v1 = [3]f64{ 0.010268, 0.000167, 0.000167 };
    const v2 = [3]f64{ 0.159258, 0.136278, 0.122389 };
    const s1 = [2]f64{ 1.0 / 15.0, 10.0 / 62.0 };
    const s2 = [2]f64{ 1.0 / 10.0, 2.0 / 50.0 };
    const z1 = [3]f64{ 9.0 / 23.0, 21.0 / 45.0, 0 / 38.0 };
    const z2 = [3]f64{ 0 / 44.0, 42.0 / 94.0, 0 / 22.0 };
    const CORRECT_ANSWERS: [8]f64 = [8]f64{
        0.021378001462867, 0.148841696605327,  0.0359722710297968,
        0.090773324285671, 0.0107515611497845, 0.00339907162713746,
        0.52726574965384,  0.545266866977794,
    };
    var pvalue: f64 = try calcPValue(&d1, &d2);
    var err: f64 = @abs(pvalue - CORRECT_ANSWERS[0]);
    try stdout.print("Test sets 1 p-value = {d:.5}\n", .{pvalue});

    pvalue = try calcPValue(&d3, &d4);
    err += @abs(pvalue - CORRECT_ANSWERS[1]);
    try stdout.print("Test sets 2 p-value = {d:.5}\n", .{pvalue});

    pvalue = try calcPValue(&d5, &d6);
    err += @abs(pvalue - CORRECT_ANSWERS[2]);
    try stdout.print("Test sets 3 p-value = {d:.5}\n", .{pvalue});

    pvalue = try calcPValue(&d7, &d8);
    try stdout.print("Test sets 4 p-value = {d:.5}\n", .{pvalue});
    err += @abs(pvalue - CORRECT_ANSWERS[3]);

    pvalue = try calcPValue(&x, &y);
    err += @abs(pvalue - CORRECT_ANSWERS[4]);
    try stdout.print("Test sets 5 p-value = {d:.5}\n", .{pvalue});

    pvalue = try calcPValue(&v1, &v2);
    err += @abs(pvalue - CORRECT_ANSWERS[5]);
    try stdout.print("Test sets 6 p-value = {d:.5}\n", .{pvalue});

    pvalue = try calcPValue(&s1, &s2);
    err += @abs(pvalue - CORRECT_ANSWERS[6]);
    try stdout.print("Test sets 7 p-value = {d:.5}\n", .{pvalue});

    pvalue = try calcPValue(&z1, &z2);
    err += @abs(pvalue - CORRECT_ANSWERS[7]);
    try stdout.print("Test sets z p-value = {d:.5}\n", .{pvalue});

    try stdout.print("the cumulative error is {}\n", .{err});

    try stdout.flush();
}

fn calcPValue(noalias array1: []const f64, noalias array2: []const f64) !f64 {
    if (array1.len <= 1 or array2.len <= 1)
        return 1.0;

    const array1_len: f64 = @as(f64, @floatFromInt(array1.len));
    const array2_len: f64 = @as(f64, @floatFromInt(array2.len));

    const fmean1: f64 = calcMean(array1);
    const fmean2: f64 = calcMean(array2);
    if (fmean1 == fmean2)
        return 1.0;

    const unbiased_sample_variance1: f64 = calcUnbiasedSampleVariance(array1, fmean1);
    const unbiased_sample_variance2: f64 = calcUnbiasedSampleVariance(array2, fmean2);

    const WELCH_T_STATISTIC: f64 = (fmean1 - fmean2) / @sqrt((unbiased_sample_variance1 / array1_len) + (unbiased_sample_variance2 / array2_len));
    const DEGREES_OF_FREEDOM: f64 = std.math.pow(f64, (unbiased_sample_variance1 / array1_len) + (unbiased_sample_variance2 / array2_len), 2.0) /
        (((unbiased_sample_variance1 * unbiased_sample_variance1) / ((array1_len * array1_len) * (array1_len - 1))) +
            ((unbiased_sample_variance2 * unbiased_sample_variance2) / ((array2_len * array2_len) * (array2_len - 1))));
    const a: f64 = DEGREES_OF_FREEDOM / 2;
    var value: f64 = DEGREES_OF_FREEDOM / ((WELCH_T_STATISTIC * WELCH_T_STATISTIC) + DEGREES_OF_FREEDOM);
    if (std.math.isInf(value) or std.math.isNan(value))
        return 1.0;
    // NOTE: lgamma for f128 ?
    const beta: f64 = std.math.lgamma(f64, a) + 0.57236494292470009 - std.math.lgamma(f64, a + 0.5);
    const acu: f64 = 0.1e-14;
    var indx: usize = undefined;
    var pp: f64 = undefined;
    var qq: f64 = undefined;
    var xx: f64 = undefined;
    if (a <= 0.0) {}
    if ((value < 0.0) or (1.0 < value))
        return value;
    if ((value == 0.0) or (value == 1.0))
        return value;
    var psq = a + 0.5;
    var cx = 1.0 - value;
    if (a < (psq * value)) {
        xx = cx;
        cx = value;
        pp = 0.5;
        qq = a;
        indx = 1;
    } else {
        xx = value;
        pp = a;
        qq = 0.5;
        indx = 0;
    }
    var term: f64 = 1.0;
    var ai: f64 = 1.0;
    value = 1.0;
    var ns: i64 = @intFromFloat(qq + (cx * psq));
    var rx = xx / cx;
    var temp = qq - ai;
    if (ns == 0)
        rx = xx;
    while (true) {
        term = ((term * temp) * rx) / (pp + ai);
        value = value + term;
        temp = @abs(term);
        if ((temp <= acu) and (temp <= (acu * value))) {
            value = (value * @exp(((pp * @log(xx)) + ((qq - 1.0) * @log(cx))) - beta)) / pp;
            if (indx != 0)
                value = 1.0 - value;
            break;
        }
        ai = ai + 1.0;
        ns -= 1;
        if (0 <= ns) {
            temp = qq - ai;
            if (ns == 0)
                rx = xx;
        } else {
            temp = psq;
            psq = psq + 1.0;
        }
    }
    return value;
}
fn calcMean(array: []const f64) f64 {
    var sum: f64 = 0.0;
    for (array) |value|
        sum += value;
    return sum / @as(f64, @floatFromInt(array.len));
}
fn calcUnbiasedSampleVariance(array: []const f64, mean: f64) f64 {
    var unbiased_sample_variance: f64 = 0.0;
    for (array) |value|
        unbiased_sample_variance += (value - mean) * (value - mean);
    return unbiased_sample_variance / (@as(f64, @floatFromInt(array.len)) - 1.0);
}
