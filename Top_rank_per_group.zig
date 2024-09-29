// https://rosettacode.org/wiki/Concatenate_two_primes_is_also_prime
// Translation of C
const std = @import("std");
const mem = std.mem;
const sort = std.sort;
const assert = std.debug.assert;
const print = std.debug.print;

pub fn main() void {
    var personnel = [_]Person{
        Person.init("Tyler Bennett", "E10297", "D101", 32000),
        Person.init("John Rappl", "E21437", "D050", 47000),
        Person.init("George Woltman", "E00127", "D101", 53500),
        Person.init("Adam Smith", "E63535", "D202", 18000),
        Person.init("Claire Buckman", "E39876", "D202", 27800),
        Person.init("David McClellan", "E04242", "D101", 41500),
        Person.init("Rich Holcomb", "E01234", "D202", 49500),
        Person.init("Nathan Adams", "E41298", "D050", 21900),
        Person.init("Richard Potter", "E43128", "D101", 15900),
        Person.init("David Motsinger", "E27002", "D202", 19250),
        Person.init("Tim Sampair", "E03033", "D101", 27000),
        Person.init("Kim Arlich", "E10001", "D190", 57000),
        Person.init("Timothy Grove", "E16398", "D190", 29900),
    };

    top(&personnel, 2);
}

fn top(personnel: []Person, count: usize) void {
    // Insertion sort is stable
    sort.insertion(Person, personnel, {}, Person.compareSalary);
    sort.insertion(Person, personnel, {}, Person.compareDepartment);

    var rank: usize = 0;
    for (personnel, 0..) |p, i| {
        if (i > 0 and !mem.eql(u8, p.department, personnel[i - 1].department)) {
            print("\n", .{});
            rank = 0;
        }
        if (rank < count) {
            print("{s} {d}: {s}\n", .{ p.department, p.salary, p.name });
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
        assert(lhs.department.len == rhs.department.len);
        for (lhs.department, rhs.department) |d1, d2| {
            if (d1 > d2) return false;
            if (d1 < d2) return true;
        }
        return false;
    }
};
