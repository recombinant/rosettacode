// https://rosettacode.org/wiki/Use_another_language_to_call_a_function
// Copied from rosettacode

// zig build-lib Use_another_language_to_call_a_function.zig
// zig run Use_another_language_to_call_a_function.c Use_another_language_to_call_a_function.lib -lc

export fn Query(data: [*c]u8, length: *usize) callconv(.c) c_int {
    const value = "Here I am";

    if (length.* >= value.len) {
        @memcpy(data[0..value.len], value);
        length.* = value.len;
        return 1;
    }

    return 0;
}
