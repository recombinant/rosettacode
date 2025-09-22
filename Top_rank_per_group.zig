// https://rosettacode.org/wiki/Concatenate_two_primes_is_also_prime
// {{works with|Zig|0.15.1}}
// {{trans|C}}
const std = @import("std");

pub fn main() !void {
    var personnel = [_]Person{
        .init("Tyler Bennett", "E10297", "D101", 32000),
        .init("John Rappl", "E21437", "D050", 47000),
        .init("George Woltman", "E00127", "D101", 53500),
        .init("Adam Smith", "E63535", "D202", 18000),
        .init("Claire Buckman", "E39876", "D202", 27800),
        .init("David McClellan", "E04242", "D101", 41500),
        .init("Rich Holcomb", "E01234", "D202", 49500),
        .init("Nathan Adams", "E41298", "D050", 21900),
        .init("Richard Potter", "E43128", "D101", 15900),
        .init("David Motsinger", "E27002", "D202", 19250),
        .init("Tim Sampair", "E03033", "D101", 27000),
        .init("Kim Arlich", "E10001", "D190", 57000),
        .init("Timothy Grove", "E16398", "D190", 29900),
    };

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try top(&personnel, 2, stdout);
}

fn top(personnel: []Person, count: usize, w: *std.Io.Writer) !void {
    // sort is stable
    std.mem.sort(Person, personnel, {}, Person.compareSalary);
    std.mem.sort(Person, personnel, {}, Person.compareDepartment);

    var rank: usize = 0;
    for (personnel, 0..) |p, i| {
        if (i > 0 and !std.mem.eql(u8, p.department, personnel[i - 1].department)) {
            try w.writeByte('\n');
            try w.flush();
            rank = 0;
        }
        if (rank < count) {
            try w.print("{s} {d}: {s}\n", .{ p.department, p.salary, p.name });
            try w.flush();
            rank += 1;
        }
    }
}

const Person = struct {
    name: []const u8,
    employee_id: []const u8,
    department: []const u8,
    salary: u32,

    fn init(name: []const u8, employee_id: []const u8, department: []const u8, salary: u32) Person {
        return .{
            .name = name,
            .employee_id = employee_id,
            .salary = salary,
            .department = department,
        };
    }
    fn compareSalary(_: void, lhs: Person, rhs: Person) bool {
        return lhs.salary > rhs.salary;
    }
    fn compareDepartment(_: void, lhs: Person, rhs: Person) bool {
        for (lhs.department, rhs.department) |d1, d2| {
            if (d1 > d2) return false;
            if (d1 < d2) return true;
        }
        return false;
    }
};
