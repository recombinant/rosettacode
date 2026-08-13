// https://rosettacode.org/wiki/Abbreviations,_simple
// {{works with|Zig|0.16.0}}
// {{trans|Python}}
const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const command_table =
    \\add 1  alter 3  backup 2  bottom 1  Cappend 2  change 1  Schange  Cinsert 2  Clast 3
    \\compress 4 copy 2 count 3 Coverlay 3 cursor 3  delete 3 Cdelete 2  down 1  duplicate
    \\3 xEdit 1 expand 3 extract 3  find 1 Nfind 2 Nfindup 6 NfUP 3 Cfind 2 findUP 3 fUP 2
    \\forward 2  get  help 1 hexType 4  input 1 powerInput 3  join 1 split 2 spltJOIN load
    \\locate 1 Clocate 2 lowerCase 3 upperCase 3 Lprefix 2  macro  merge 2 modify 3 move 2
    \\msg  next 1 overlay 1 parse preserve 4 purge 3 put putD query 1 quit  read recover 3
    \\refresh renum 3 repeat 3 replace 1 Creplace 2 reset 3 restore 4 rgtLEFT right 2 left
    \\2  save  set  shift 2  si  sort  sos  stack 3 status 4 top  transfer 3  type 1  up 1
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
    var optional_word: ?[]const u8 = null;
    while (true) {
        if (optional_word == null) {
            optional_word = it.next();
            if (optional_word == null) break;
        }
        const this_word = std.ascii.allocUpperString(gpa, optional_word.?) catch @panic("OOM");
        if (it.next()) |next_word| {
            const abbrev_len = std.fmt.parseInt(usize, next_word, 10) catch {
                lookup.put(gpa, this_word, this_word.len) catch @panic("OOM");
                optional_word = next_word;
                continue;
            };
            lookup.put(gpa, this_word, abbrev_len) catch @panic("OOM");
            optional_word = null;
        } else {
            lookup.put(gpa, this_word, this_word.len) catch @panic("OOM");
            break;
        }
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
