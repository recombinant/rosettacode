// https://rosettacode.org/wiki/Compound_data_type
// from https://github.com/tiehuis/zig-rosetta
// {{works with|Zig|0.17.0}}
pub fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T,
    };
}

pub const IntPoint = Point(i32);
pub const FloatPoint = Point(f32);
