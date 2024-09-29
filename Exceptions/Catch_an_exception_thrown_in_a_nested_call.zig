// https://rosettacode.org/wiki/Exceptions/Catch_an_exception_thrown_in_a_nested_call
// from https://github.com/tiehuis/zig-rosetta
const std = @import("std");
const print = std.debug.print;

// Zig doesn't have exceptions, but its error handling system can represent this control flow.

// Running this program will result in the following error-return-trace.

// U0 Caught
// error: U1
// ./Catch_an_exception_thrown_in_a_nested_call.zig:51:5: 0x371055 in baz (Catch_an_exception_thrown_in_a_nested_call.exe.obj)
//     return if (!pred) error.U0 else error.U1;
//     ^
// ./Catch_an_exception_thrown_in_a_nested_call.zig:47:5: 0x37116c in bar (Catch_an_exception_thrown_in_a_nested_call.exe.obj)
//     try baz(pred);
//     ^
// ./Catch_an_exception_thrown_in_a_nested_call.zig:38:17: 0x37120e in foo (Catch_an_exception_thrown_in_a_nested_call.exe.obj)
//                 return err;
//                 ^
// ./Catch_an_exception_thrown_in_a_nested_call.zig:55:5: 0x3714a5 in main (Catch_an_exception_thrown_in_a_nested_call.exe.obj)
//     try foo();
//     ^

fn foo() !void {
    var b = false;
    while (true) {
        bar(b) catch |err| switch (err) {
            error.U0 => print("U0 Caught\n", .{}),
            error.U1 => {
                // Zig requires us to handle the error here. We can simulate
                // a rethrow by returning the error to the caller.
                return err;
            },
        };
        b = !b;
    }
}

fn bar(pred: bool) !void {
    try baz(pred);
}

fn baz(pred: bool) !void {
    return if (!pred) error.U0 else error.U1;
}

pub fn main() !void {
    try foo();
}
