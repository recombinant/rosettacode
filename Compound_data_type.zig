// https://rosettacode.org/wiki/Compound_data_type
// from https://github.com/tiehuis/zig-rosetta
fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T,
    };
}

const IntPoint = Point(i32);
const FloatPoint = Point(f32);
