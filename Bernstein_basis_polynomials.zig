// https://rosettacode.org/wiki/Bernstein_basis_polynomials
// {{works with|Zig|0.15.1}}
// {{trans|Go}}
const std = @import("std");

const print = std.debug.print;

fn toBern2(a: []const f64) [3]f64 {
    return [3]f64{ a[0], a[0] + a[1] / 2, a[0] + a[1] + a[2] };
}

// uses de Casteljau's algorithm
fn evalBern2(b: []const f64, t: f64) f64 {
    const s = 1.0 - t;
    const b01 = s * b[0] + t * b[1];
    const b12 = s * b[1] + t * b[2];
    return s * b01 + t * b12;
}

fn toBern3(a: []const f64) [4]f64 {
    var b: [4]f64 = undefined;
    b[0] = a[0];
    b[1] = a[0] + a[1] / 3;
    b[2] = a[0] + a[1] * 2 / 3 + a[2] / 3;
    b[3] = a[0] + a[1] + a[2] + a[3];
    return b;
}

// uses de Casteljau's algorithm
fn evalBern3(b: []const f64, t: f64) f64 {
    const s = 1.0 - t;
    const b01 = s * b[0] + t * b[1];
    const b12 = s * b[1] + t * b[2];
    const b23 = s * b[2] + t * b[3];
    const b012 = s * b01 + t * b12;
    const b123 = s * b12 + t * b23;
    return s * b012 + t * b123;
}

fn bern2to3(q: []const f64) [4]f64 {
    var c: [4]f64 = undefined;
    c[0] = q[0];
    c[1] = q[0] / 3 + q[1] * 2 / 3;
    c[2] = q[1] * 2 / 3 + q[2] / 3;
    c[3] = q[2];
    return c;
}

// uses Horner's rule
fn evalMono2(a: []const f64, t: f64) f64 {
    return a[0] + (t * (a[1] + (t * a[2])));
}

// uses Horner's rule
fn evalMono3(a: []const f64, t: f64) f64 {
    return a[0] + (t * (a[1] + (t * (a[2] + (t * a[3])))));
}

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var pm: std.ArrayList(f64) = .empty;
    defer pm.deinit(allocator);
    try pm.appendSlice(allocator, &[_]f64{ 1, 0, 0 });

    var qm: std.ArrayList(f64) = .empty;
    defer qm.deinit(allocator);
    try qm.appendSlice(allocator, &[_]f64{ 1, 2, 3 });

    var rm: std.ArrayList(f64) = .empty;
    defer rm.deinit(allocator);
    try rm.appendSlice(allocator, &[_]f64{ 1, 2, 3, 4 });

    var x: f64 = undefined;
    var y: f64 = undefined;
    var m: f64 = undefined;
    print("Subprogram(1) examples:\n", .{});
    const pb2 = toBern2(pm.items);
    const qb2 = toBern2(qm.items);
    print("mono {any} --> bern {any}\n", .{ pm.items, pb2 });
    print("mono {any} --> bern {any}\n", .{ qm.items, qb2 });

    print("\nSubprogram(2) examples:\n", .{});
    x = 0.25;
    y = evalBern2(&pb2, x);
    m = evalMono2(pm.items, x);
    print("p({d:.2}) = {d} (mono {d})\n", .{ x, y, m });
    x = 7.5;
    y = evalBern2(&pb2, x);
    m = evalMono2(pm.items, x);
    print("p({d:.2}) = {d} (mono {d})\n", .{ x, y, m });
    x = 0.25;
    y = evalBern2(&qb2, x);
    m = evalMono2(qm.items, x);
    print("q({d:.2}) = {d:6.2} (mono {d:6.2})\n", .{ x, y, m });
    x = 7.5;
    y = evalBern2(&qb2, x);
    m = evalMono2(qm.items, x);
    print("q({d:.2}) = {d:6.2} (mono {d:6.2})\n", .{ x, y, m });

    print("\nSubprogram(3) examples:\n", .{});
    try pm.append(allocator, 0);
    try qm.append(allocator, 0);
    const pb3 = toBern3(pm.items);
    const qb3 = toBern3(qm.items);
    const rb3 = toBern3(rm.items);
    const f = "mono {any} --> bern {any}\n";
    print(f, .{ pm.items, pb3 });
    print(f, .{ qm.items, qb3 });
    print(f, .{ rm.items, rb3 });

    print("\nSubprogram(4) examples:\n", .{});
    x = 0.25;
    y = evalBern3(&pb3, x);
    m = evalMono3(pm.items, x);
    print("p({d:.2}) = {d} (mono {d})\n", .{ x, y, m });
    x = 7.5;
    y = evalBern3(&pb3, x);
    m = evalMono3(pm.items, x);
    print("p({d:.2}) = {d} (mono {d})\n", .{ x, y, m });
    x = 0.25;
    y = evalBern3(&qb3, x);
    m = evalMono3(qm.items, x);
    print("q({d:.2}) = {d:9.4} (mono {d:7.2})\n", .{ x, y, m });
    x = 7.5;
    y = evalBern3(&qb3, x);
    m = evalMono3(qm.items, x);
    print("q({d:.2}) = {d:9.4} (mono {d:7.2})\n", .{ x, y, m });
    x = 0.25;
    y = evalBern3(&rb3, x);
    m = evalMono3(rm.items, x);
    print("r({d:.2}) = {d:9.4} (mono {d:7.2})\n", .{ x, y, m });
    x = 7.5;
    y = evalBern3(&rb3, x);
    m = evalMono3(rm.items, x);
    print("r({d:.2}) = {d:9.4} (mono {d:7.2})\n", .{ x, y, m });

    print("\nSubprogram(5) examples:\n", .{});
    const pc = bern2to3(&pb2);
    const qc = bern2to3(&qb2);
    print("mono {any} --> bern {any}\n", .{ pb2, pc });
    print("mono {any} --> bern {d:.2}\n", .{ qb2, @as(@Vector(4, f64), qc) });
}
