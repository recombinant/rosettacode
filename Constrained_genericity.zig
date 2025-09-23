// https://rosettacode.org/wiki/Constrained_genericity
// {{works with|Zig|0.15.1}}

// This file should fail to compile.
// works with Zig 0.11.0, 0.12.1, 0.13.0, 0.14.1 and 0.15.1

// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const meta = std.meta;

fn FoodBox(comptime T: type) type {
    if (!meta.hasFn(T, "eat"))
        @compileError("Type " ++ @typeName(T) ++ " does not have required public function `eat`");

    return struct {
        const Self = @This();

        fn init() Self {
            return Self{};
        }
    };
}

const Carrot = struct {
    pub fn eat() void {}
};

const Car = struct {};

pub fn main() void {
    const box1 = FoodBox(Carrot).init();
    _ = &box1;

    // Constrained_genericity.zig:8:9: error: Type Constrained_genericity.Car does not have required public function `eat`
    //         @compileError("Type " ++ @typeName(T) ++ " does not have required public function `eat`");
    //         ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Constrained_genericity.zig:37:25: note: called from here
    //     const box2 = FoodBox(Car).init();
    //                  ~~~~~~~^~~~~

    // Will fail with the above error.
    const box2 = FoodBox(Car).init();
    _ = &box2;
}
