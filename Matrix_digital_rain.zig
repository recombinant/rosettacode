// https://rosettacode.org/wiki/Matrix_digital_rain
// Translation of C

// Original C copyright notice...
// /*******************************************************************************
// *
// * Digital ASCII rain - the single thread variant.
// * 2012 (C) by Author, 2020 GPL licensed for RossetaCode
// *
// *******************************************************************************/
const std = @import("std");

const c = @cImport({
    @cInclude("conio.h"); // console operations
    @cInclude("windows.h"); // just the Microsoft Windows main header for C
});

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = prng.random();

    var digital_rain = try DigitalRain.init(allocator, random);
    defer digital_rain.deinit(allocator);

    digital_rain.loop();
}

const DigitalRain = struct {
    hStdOut: c.HANDLE, // the handle to console "out"
    csbi: c.CONSOLE_SCREEN_BUFFER_INFO, // numbers of rows, columns etc.

    buffer: []c.CHAR_INFO, // a  big enough buffer
    buffer_size: c.COORD, // the size of buffer etc.
    buffer_coord: c.COORD,
    table: []Data,
    random: std.Random,

    fn init(allocator: std.mem.Allocator, random: std.Random) !DigitalRain {
        const hStdOut = c.GetStdHandle(c.STD_OUTPUT_HANDLE);
        _ = c.SetConsoleTitleA("Digital ASCII rain");

        //
        // An attempt to run in the full-screen mode.
        //
        const args = try std.process.argsAlloc(allocator);
        std.log.debug("args {}", .{args.len});
        std.process.exit(0);
        if (args.len == 1) {
            var coord: c.COORD = undefined;
            var cci: c.CONSOLE_CURSOR_INFO = .{
                .bVisible = c.FALSE,
                .dwSize = 0,
            };
            _ = c.SetConsoleDisplayMode(hStdOut, c.CONSOLE_FULLSCREEN_MODE, &coord);
            _ = c.SetConsoleCursorInfo(hStdOut, &cci);
        }
        std.process.argsFree(allocator, args);

        var csbi: c.CONSOLE_SCREEN_BUFFER_INFO = undefined;
        _ = c.GetConsoleScreenBufferInfo(hStdOut, &csbi);
        _ = c.SetConsoleTextAttribute(hStdOut, c.FOREGROUND_GREEN);

        const buffer_size = c.COORD{
            .X = 1,
            .Y = csbi.dwSize.Y - 1,
        };

        const table = try allocator.alloc(Data, @intCast(csbi.dwSize.X));
        for (table, 0..) |*column, j|
            columnInit(random, column, @intCast(j), @intCast(buffer_size.Y));

        return DigitalRain{
            .hStdOut = hStdOut,
            .csbi = csbi,
            .buffer_size = buffer_size,
            .buffer_coord = .{
                .X = 0,
                .Y = 0,
            },
            .buffer = try allocator.alloc(c.CHAR_INFO, @intCast(buffer_size.Y)),
            .table = table,
            .random = random,
        };
    }
    fn deinit(self: *DigitalRain, allocator: std.mem.Allocator) void {
        defer allocator.free(self.table);
        allocator.free(self.buffer);
    }

    fn columnInit(random: std.Random, data: *Data, x: c.SHORT, y: c.SHORT) void {
        const s = c.SMALL_RECT{
            .Left = x,
            .Top = 0,
            .Bottom = y - 2,
            .Right = x,
        };

        const d = c.SMALL_RECT{
            .Left = s.Left,
            .Top = s.Top + 1,
            .Right = s.Right,
            .Bottom = s.Bottom + 1,
        };

        data.* = .{
            .armed = 0,
            .show = randomShow(random),
            .delay = randomDelay(random),
            .ncp = .{ .X = x, .Y = 0 },
            .s = s,
            .d = d,
        };
    }

    fn columnRun(self: *const DigitalRain, data: *Data) void {
        //
        // Shift down a column.
        //
        _ = c.ReadConsoleOutputA(self.hStdOut, self.buffer.ptr, self.buffer_size, self.buffer_coord, &data.s);
        _ = c.WriteConsoleOutputA(self.hStdOut, self.buffer.ptr, self.buffer_size, self.buffer_coord, &data.d);

        //
        // If show == true then generate a new character.
        // If show == false write the space to erase.
        //
        var ch: u8 = undefined;
        var a: c.WORD = undefined;
        if (data.show) {
            ch = if (self.random.intRangeAtMost(u8, 1, 100) <= 15) ' ' else self.random.intRangeAtMost(u8, 'a', 'z');
            a = @intCast(c.FOREGROUND_GREEN | (if (self.random.intRangeAtMost(u8, 1, 100) > 10) 0 else c.FOREGROUND_INTENSITY));
        } else {
            ch = ' ';
            a = c.FOREGROUND_GREEN;
        }

        var result: c.DWORD = undefined;
        _ = c.WriteConsoleOutputCharacterA(self.hStdOut, &ch, 1, data.ncp, &result);
        _ = c.WriteConsoleOutputAttribute(self.hStdOut, @ptrCast(&a), 1, data.ncp, &result);

        //
        // Randomly regenerate the delay and the visibility state of the column.
        //
        if (randomRegenerate(self.random)) data.show = randomShow(self.random);
        if (randomRegenerate(self.random)) data.delay = randomDelay(self.random);

        data.armed = c.GetTickCount() + data.delay;
    }

    /// Main loop. Sleep(1) significally decreases the CPU load.
    fn loop(self: *DigitalRain) void {
        while (c._kbhit() == 0) {
            const t = c.GetTickCount();
            for (self.table) |*column|
                if (column.armed < t) self.columnRun(column);
            c.Sleep(1);
        }
    }
};

/// A structure that holds data that is distinct for each column.
const Data = struct {
    armed: c.DWORD, // time in ms to synchronize
    delay: c.DWORD, // armed = current_time + delay
    show: bool, // true - draw, false - erase
    ncp: c.COORD, // position for drawing new characters
    s: c.SMALL_RECT, // source regions for copy
    d: c.SMALL_RECT, // destination regions for copy
};

fn randomShow(random: std.Random) bool {
    return random.uintAtMost(u8, 99) < 65;
}

fn randomDelay(random: std.Random) c.DWORD {
    return @intCast(random.uintAtMost(c.DWORD, 150) + random.uintAtMost(c.DWORD, 150) + random.uintAtMost(c.DWORD, 150));
}

fn randomRegenerate(random: std.Random) bool {
    return random.uintAtMost(u8, 99) < 2;
}
