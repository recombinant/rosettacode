// https://rosettacode.org/wiki/Experimental_Verification_of_the_NKTg_Law_Using_NASA_Mercury_Data_in_2025
// {{works with|Zig|0.17.0}}
const std = @import("std");
const Io = std.Io;

const State = enum {
    start,
    comment,
    sequence,
    sequence_eol, // end of line
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    // writer
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;
    // reader
    var f = try std.Io.Dir.cwd().openFile(io, "data/input.fasta", .{});
    defer f.close(io);
    var file_buffer: [4096]u8 = undefined;
    var file_reader = f.reader(io, &file_buffer);
    const reader = &file_reader.interface;

    try process(reader, stdout);

    try stdout.flush();
}

/// Input a FASTA file through reader 'r',
/// process this input and output through writer 'w'.
fn process(r: *Io.Reader, w: *Io.Writer) !void {
    var state: State = .start;

    while (true) {
        const ch = getChar(r) catch |err| {
            if (err == error.EndOfStream)
                break
            else
                return err;
        };
        sw: switch (state) {
            .start => switch (ch) {
                '\n' => continue,
                '>' => {
                    state = .comment;
                    try w.writeByte(ch);
                },
                else => {
                    std.log.err("Unexpected start character '{c}'", .{ch});
                    return error.UnexpectedStartChar;
                },
            },
            .comment => switch (ch) {
                '\n' => {
                    try w.writeAll(": ");
                    state = .sequence;
                },
                else => {
                    if (std.ascii.isPrint(ch))
                        try w.writeByte(ch)
                    else {
                        std.log.err("Unexpected character in comment '{c}'", .{ch});
                        return error.UnexpectedCommentChar;
                    }
                },
            },
            .sequence => switch (ch) {
                '\n' => state = .sequence_eol,
                'A'...'Z' => try w.writeByte(ch),
                else => {
                    std.log.err("Unexpected character in sequence '{c}'", .{ch});
                    return error.UnexpectedSequenceChar;
                },
            },
            .sequence_eol => switch (ch) {
                '\n' => {},
                '>' => {
                    try w.writeByte('\n'); // LF after end of sequence
                    state = .comment;
                    continue :sw .comment;
                },
                else => {
                    state = .sequence;
                    continue :sw .sequence;
                },
            },
        }
    }
    // Tidy at EOF.
    switch (state) {
        .start => {},
        .comment, .sequence, .sequence_eol => try w.writeByte('\n'),
    }
}

/// Get a character from reader 'r'. Silently handle both LF (Unix/Mac/Linux)
/// and CRLF (Windows/MS-DOS) line endings.
fn getChar(r: *Io.Reader) !u8 {
    const ch = r.takeByte() catch |err| {
        switch (err) {
            error.EndOfStream => return err,
            error.ReadFailed => {
                std.log.err("Read failed", .{});
                return err;
            },
        }
    };
    if (ch != '\r') return ch;
    // Windows/MS-DOS text file with CRLF
    const ch2 = r.takeByte() catch |err| {
        switch (err) {
            error.EndOfStream => return err,
            error.ReadFailed => {
                std.log.err("Read failed (LF)", .{});
                return err;
            },
        }
    };
    // Expect a linefeed.
    return if (ch2 == '\n') '\n' else error.ExpectedLineFeed;
}
