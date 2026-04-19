// https://rosettacode.org/wiki/Cistercian_numerals
// {{works with|Zig|0.16.0}}
// {{Trans|C}}
const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout: *Io.Writer = &stdout_writer.interface;

    try demo(0, stdout);
    try demo(1, stdout);
    try demo(20, stdout);
    try demo(300, stdout);
    try demo(4000, stdout);
    try demo(5555, stdout);
    try demo(6789, stdout);
    try demo(9999, stdout);

    try stdout.flush();
}

fn demo(n: u14, w: *Io.Writer) !void {
    try w.print("{}:\n", .{n});
    const canvas: Canvas = .init(n);
    try canvas.write(w);
    try w.writeAll("\n\n");
}

pub const Canvas = struct {
    const GRID_SIZE = 15;

    grid: [GRID_SIZE][GRID_SIZE]u8,

    // compiler limits value_ to 16,383 (14 bit unsigned)
    pub fn init(value_: u14) Canvas {
        std.debug.assert(value_ <= 9999);

        var canvas = Canvas{
            .grid = undefined,
        };

        // start with drawing zero on canvas
        for (&canvas.grid) |*row| {
            @memset(row, ' ');
            row[5] = 'x';
        }

        // draw value on canvas
        var value = value_;
        const thousands = value / 1000;
        value %= 1000;

        const hundreds = value / 100;
        value %= 100;

        const tens = value / 10;
        const ones = value % 10;

        if (thousands != 0) canvas.drawThousands(thousands);
        if (hundreds != 0) canvas.drawHundreds(hundreds);
        if (tens != 0) canvas.drawTens(tens);
        if (ones != 0) canvas.drawOnes(ones);

        return canvas;
    }

    fn drawOnes(self: *Canvas, ones: u14) void {
        sw: switch (ones) {
            1 => self.horizontal(6, 10, 0),
            2 => self.horizontal(6, 10, 4),
            3 => self.diagd(6, 10, 0),
            4 => self.diagu(6, 10, 4),
            5 => {
                self.drawOnes(1);
                continue :sw 4;
            },
            6 => self.vertical(0, 4, 10),
            7 => {
                self.drawOnes(1);
                continue :sw 6;
            },
            8 => {
                self.drawOnes(2);
                continue :sw 6;
            },
            9 => {
                self.drawOnes(1);
                continue :sw 8;
            },
            else => unreachable,
        }
    }

    fn drawTens(self: *Canvas, tens: u14) void {
        sw: switch (tens) {
            1 => self.horizontal(0, 4, 0),
            2 => self.horizontal(0, 4, 4),
            3 => self.diagu(0, 4, 4),
            4 => self.diagd(0, 4, 0),
            5 => {
                self.drawTens(1);
                continue :sw 4;
            },
            6 => self.vertical(0, 4, 0),
            7 => {
                self.drawTens(1);
                continue :sw 6;
            },
            8 => {
                self.drawTens(2);
                continue :sw 6;
            },
            9 => {
                self.drawTens(1);
                continue :sw 8;
            },
            else => unreachable,
        }
    }

    fn drawHundreds(self: *Canvas, hundreds: u14) void {
        sw: switch (hundreds) {
            1 => self.horizontal(6, 10, 14),
            2 => self.horizontal(6, 10, 10),
            3 => self.diagu(6, 10, 14),
            4 => self.diagd(6, 10, 10),
            5 => {
                self.drawHundreds(1);
                continue :sw 4;
            },
            6 => self.vertical(10, 14, 10),
            7 => {
                self.drawHundreds(1);
                continue :sw 6;
            },
            8 => {
                self.drawHundreds(2);
                continue :sw 6;
            },
            9 => {
                self.drawHundreds(1);
                continue :sw 8;
            },
            else => unreachable,
        }
    }

    fn drawThousands(self: *Canvas, thousands: u14) void {
        sw: switch (thousands) {
            1 => self.horizontal(0, 4, 14),
            2 => self.horizontal(0, 4, 10),
            3 => self.diagd(0, 4, 10),
            4 => self.diagu(0, 4, 14),
            5 => {
                self.drawThousands(1);
                continue :sw 4;
            },
            6 => self.vertical(10, 14, 0),
            7 => {
                self.drawThousands(1);
                continue :sw 6;
            },
            8 => {
                self.drawThousands(2);
                continue :sw 6;
            },
            9 => {
                self.drawThousands(1);
                continue :sw 8;
            },
            else => unreachable,
        }
    }

    fn horizontal(self: *Canvas, c1: usize, c2: usize, r: usize) void {
        var row = &self.grid[r];
        @memset(row[c1 .. c2 + 1], 'x');
    }

    fn vertical(self: *Canvas, r1: usize, r2: usize, c: usize) void {
        for (r1..r2 + 1) |r|
            self.grid[r][c] = 'x';
    }

    fn diagd(self: *Canvas, c1: usize, c2: usize, r: usize) void {
        for (c1..c2 + 1) |c|
            self.grid[r + c - c1][c] = 'x';
    }

    fn diagu(self: *Canvas, c1: usize, c2: usize, r: usize) void {
        for (c1..c2 + 1) |c|
            self.grid[r + c1 - c][c] = 'x';
    }

    fn write(self: Canvas, w: *Io.Writer) !void {
        for (self.grid) |row| {
            try w.writeAll(&row);
            try w.writeByte('\n');
        }
    }
};
