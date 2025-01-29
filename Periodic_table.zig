// https://rosettacode.org/wiki/Periodic_table
// Translation of Python
const std = @import("std");

fn perta(atomic: u8) struct { u8, u8 } {
    const NOBLES = [_]u8{ 2, 10, 18, 36, 54, 86, 118 };
    const INTERTWINED = [_]u8{ 0, 0, 0, 0, 0, 57, 89 };
    const INTERTWINING_SIZE = 14;
    const LINE_WIDTH = 18;

    var prev_noble: u8 = 0;
    var row: u8 = 0;
    var col: u8 = undefined;
    for (NOBLES) |noble| {
        if (atomic <= noble) {
            // we are at the good row. We now need to determine the column
            const nb_elem = noble - prev_noble; // number of elements on that row
            const rank = atomic - prev_noble; // rank of the input element among elements
            if (INTERTWINED[row] != 0 and INTERTWINED[row] <= atomic and atomic <= INTERTWINED[row] + INTERTWINING_SIZE) {
                // either lanthanide or actinide
                row += 2;
                col = rank + 1;
            } else {
                // neither lanthanide nor actinide
                // handle empty spaces between 1-2, 4-5 and 12-13.
                const nb_empty = LINE_WIDTH -% nb_elem; // spaces count as columns
                const inside_left_element_rank: u8 = if (noble > 2) 2 else 1;
                col = rank +% if (rank > inside_left_element_rank) nb_empty else 0;
            }
            break;
        }
        prev_noble = noble;
        row += 1;
    }
    return .{ row + 1, col };
}

const testing = std.testing;
test perta {
    const tests = [_]struct { u8, struct { u8, u8 } }{
        .{ 1, .{ 1, 1 } },
        .{ 2, .{ 1, 18 } },
        .{ 29, .{ 4, 11 } },
        .{ 42, .{ 5, 6 } },
        .{ 58, .{ 8, 5 } },
        .{ 59, .{ 8, 6 } },
        .{ 57, .{ 8, 4 } },
        .{ 71, .{ 8, 18 } },
        .{ 72, .{ 6, 4 } },
        .{ 89, .{ 9, 4 } },
        .{ 90, .{ 9, 5 } },
        .{ 103, .{ 9, 18 } },
    };
    for (tests) |t| {
        const input = t[0];

        const expected = t[1];
        const actual = perta(input);

        try testing.expectEqual(expected, actual);
    }
}
