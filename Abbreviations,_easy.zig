// https://rosettacode.org/wiki/Abbreviations,_simple
// {{works with|Zig|0.16.0}}
// {{trans|Python}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const command_table =
    \\  Add ALTer  BAckup Bottom  CAppend Change SCHANGE  CInsert CLAst COMPress COpy
    \\  COUnt COVerlay CURsor DELete CDelete Down DUPlicate Xedit EXPand EXTract Find
    \\  NFind NFINDUp NFUp CFind FINdup FUp FOrward GET Help HEXType Input POWerinput
    \\  Join SPlit SPLTJOIN  LOAD  Locate CLocate  LOWercase UPPercase  LPrefix MACRO
    \\  MErge MODify MOve MSG Next Overlay PARSE PREServe PURge PUT PUTD  Query  QUIT
    \\  READ  RECover REFRESH RENum REPeat  Replace CReplace  RESet  RESTore  RGTLEFT
    \\  RIght LEft  SAVE  SET SHift SI  SORT  SOS  STAck STATus  TOP TRAnsfer Type Up
;

const user_words = "riG   rePEAT copies  put mo   rest    types   fup.    6       poweRin";

const CommandLookup = std.StringHashMapUnmanaged(usize);
const AbbreviationLookup = std.StringHashMapUnmanaged([]const u8);

pub fn main(init: std.process.Init) !void {
    const io: Io = init.io;
    const gpa: Allocator = init.gpa;

    var length_lookup = findAbbreviationLengths(gpa, command_table);
    defer {
        var it = length_lookup.keyIterator();
        while (it.next()) |key|
            gpa.free(key.*);
        length_lookup.deinit(gpa);
    }

    // abbreviation_lookup uses length_lookup keys, so length_lookup should not go
    // out of scope before abbreviation_lookup.
    var abbreviation_lookup = findAbbreviations(gpa, length_lookup);
    defer abbreviation_lookup.deinit(gpa);

    const full_words = parseUserString(gpa, user_words, abbreviation_lookup);
    defer gpa.free(full_words);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Input:  {s}\n", .{user_words});
    try stdout.print("Output: {s}\n", .{full_words});

    try stdout.flush();
}

fn findAbbreviationLengths(gpa: Allocator, command_table_text: []const u8) CommandLookup {
    var lookup: CommandLookup = .empty;

    var it = std.mem.tokenizeAny(u8, command_table_text, " \n");
    while (it.next()) |word| {
        var abbrev_len: usize = 0;
        for (word) |c| {
            if (!std.ascii.isUpper(c)) // Assume only leading uppercase
                break;
            abbrev_len += 1;
        }
        if (abbrev_len == 0) abbrev_len = word.len; // No abbreviation permitted

        const command = std.ascii.allocUpperString(gpa, word) catch @panic("OOM");
        lookup.put(gpa, command, abbrev_len) catch @panic("OOM");
    }
    return lookup;
}

fn findAbbreviations(gpa: Allocator, lookup: CommandLookup) AbbreviationLookup {
    var abbreviations: AbbreviationLookup = .empty;

    var it = lookup.iterator();
    while (it.next()) |entry| {
        const command = entry.key_ptr.*;
        const min_len = entry.value_ptr.*;
        for (min_len..command.len + 1) |len| {
            const abbr = command[0..len];
            abbreviations.put(gpa, abbr, command) catch @panic("OOM");
        }
    }
    return abbreviations;
}

fn parseUserString(gpa: Allocator, user_string_: []const u8, abbreviations: AbbreviationLookup) []const u8 {
    var word_list: std.ArrayList([]const u8) = .empty;
    defer word_list.deinit(gpa);

    const user_string = std.ascii.allocUpperString(gpa, user_string_) catch @panic("OOM");
    defer gpa.free(user_string);

    var it = std.mem.tokenizeAny(u8, user_string, " \n");
    while (it.next()) |word|
        word_list.append(gpa, abbreviations.get(word) orelse "*error*") catch @panic("OOM");

    return std.mem.join(gpa, " ", word_list.items) catch @panic("OOM");
}
