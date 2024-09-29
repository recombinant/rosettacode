// https://rosettacode.org/wiki/Dominoes

// TODO: Work in Progress

const std = @import("std");
const mem = std.mem;
const time = std.time;
const print = std.debug.print;

const Tableau = [7][8]u3;

const tableau = Tableau{
    [8]u3{ 0, 5, 1, 3, 2, 2, 3, 1 },
    [8]u3{ 0, 5, 5, 0, 5, 2, 4, 6 },
    [8]u3{ 4, 3, 0, 3, 6, 6, 2, 0 },
    [8]u3{ 0, 6, 2, 3, 5, 1, 2, 6 },
    [8]u3{ 1, 1, 3, 0, 0, 2, 4, 5 },
    [8]u3{ 2, 1, 4, 3, 3, 4, 6, 6 },
    [8]u3{ 6, 4, 5, 1, 5, 4, 1, 4 },
};

const tableau2 = Tableau{
    [8]u3{ 6, 4, 2, 2, 0, 6, 5, 0 },
    [8]u3{ 1, 6, 2, 3, 4, 1, 4, 3 },
    [8]u3{ 2, 1, 0, 2, 3, 5, 5, 1 },
    [8]u3{ 1, 3, 5, 0, 5, 6, 1, 0 },
    [8]u3{ 4, 2, 6, 0, 4, 0, 1, 1 },
    [8]u3{ 4, 4, 2, 0, 5, 3, 6, 3 },
    [8]u3{ 6, 6, 5, 2, 5, 3, 3, 4 },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var dominoes = std.ArrayList([2]u3).init(allocator);
    defer dominoes.deinit();

    for (0..tableau[0].len) |j|
        for (0..tableau.len) |i|
            if (i <= j)
                try dominoes.append(.{ @truncate(i), @truncate(j) });

    for ([2]Tableau{ tableau, tableau2 }) |t| {
        var t0 = try time.Timer.start();
        const lays = findLayouts(t, dominoes);
        printLayout(lays[0]);
        const lc = lays.len;
        const pl: []const u8 = if (lc > 1) "s" else "";
        const fo: []const u8 = if (lc > 1) " (first one shown)" else "";
        print("{} layout{s} found{s}.", .{ lc, pl, fo });
        print("Processed in {}\n", .{std.fmt.fmtDuration(t0.read())});
    }
}

// var containsDom = Fn.new { |l, m, n|  // assumes m <= n
//     for (i in 0...l.len) {
//         var d = l[i]
//         if (d[0] == m && d[1] == n) return true
//     }
//     return false
// }

// var copyTab = Fn.new { |t|
//     var c = List.filled(t.len, null)
//     for (r in 0...t.len) c[r] = t[r].toList
//     return c
// }

// var sorted = Fn.new { |dom| (dom[0] > dom[1]) ? [dom[1], dom[0]] : dom }

fn findLayouts(tab: Tableau, doms: [][2]u3) [][][]u3 {
    const nrows = tab.len;
    const ncols = tab[0].len;
    _ = doms; // autofix
    _ = nrows; // autofix
    _ = ncols; // autofix
    //     var m = List.filled(nrows, null)
    //     for (i in 0...nrows) m[i] = List.filled(ncols, -1)
    //     var patterns = [ [m, [], []] ]
    //     var count = 0
    //     while (true) {
    //         var newpat = []
    //         for (pat in patterns) {
    //             var ut = pat[0]
    //             var ud = pat[1]
    //             var up = pat[2]
    //             var pos = null
    //             for (j in 0...ncols) {
    //                 var breakOuter = false
    //                 for (i in 0...nrows) {
    //                    if (ut[i][j] == -1) {
    //                        pos = [i, j]
    //                        breakOuter = true
    //                        break
    //                    }
    //                 }
    //                 if (breakOuter) break
    //             }
    //             if (!pos) continue
    //             var row = pos[0]
    //             var col = pos[1]
    //             if (row < nrows - 1 && ut[row+1][col] == -1) {
    //                 var dom = sorted.call([tab[row][col], tab[row+1][col]])
    //                 if (!containsDom.call(ud, dom[0], dom[1])) {
    //                     var newut = copyTab.call(ut)
    //                     newut[row][col] = tab[row][col]
    //                     newut[row+1][col] = tab[row+1][col]
    //                     newpat.add([newut, ud + [sorted.call( [tab[row][col], tab[row+1][col]])],
    //                         up + [row, col, row+1, col]])
    //                 }
    //             }
    //             if (col < ncols - 1  && ut[row][col+1] == -1) {
    //                 var dom = sorted.call([tab[row][col], tab[row][col+1]])
    //                 if (!containsDom.call(ud, dom[0], dom[1])) {
    //                     var newut = copyTab.call(ut)
    //                     newut[row][col] = tab[row][col]
    //                     newut[row][col+1] = tab[row][col+1]
    //                     newpat.add([newut, ud + [sorted.call([tab[row][col], tab[row][col+1]])],
    //                         up + [row, col, row, col+1]])
    //                 }
    //             }
    //         }
    //         if (newpat.len == 0) break
    //         patterns = newpat
    //         if (patterns[0][-1].len == doms.len) break
    //     }
    //     return patterns
}

// var printLayout = Fn.new { |pattern|
//     var tab = pattern[0]
//     var dom = pattern[1]
//     var pos = pattern[2]
//     var bytes = List.filled(tab.len*2, null)
//     for (i in 0...bytes.len) bytes[i] = List.filled(tab[0].len*2 - 1, " ")
//     var idx = 0
//     while (idx < pos.len-1) {
//         var p = pos[idx..idx+3]
//         var x1 = p[0]
//         var y1 = p[1]
//         var x2 = p[2]
//         var y2 = p[3]
//         var n1 = tab[x1][y1]
//         var n2 = tab[x2][y2]
//         bytes[x1*2][y1*2] = String.fromByte(48+n1)
//         bytes[x2*2][y2*2] = String.fromByte(48+n2)
//         if (x1 == x2) { // horizontal
//             bytes[x1*2][y1*2 + 1] = "+"
//         } else if (y1 == y2) { // vertical
//             bytes[x1*2 + 1][y1*2] = "+"
//         }
//         idx = idx + 4
//     }

//     for (i in 0...bytes.len) {
//         System.print(bytes[i].join())
//     }
// }
