// https://rosettacode.org/wiki/Chinese_zodiac
// {{works with|Zig|0.15.1}}
// {{trans|zkl}}
const std = @import("std");
const print = std.debug.print;

pub fn main() void {
    const years = [6]u14{
        1935, 1938, 1968,
        1972, 1976, 2017,
    };
    for (years) |year| {
        print("{d}: ", .{year});
        print("{s}{s} ({s}-{s}, {s} {s}; {s})\n", ceToChineseZodiac(year));
    }
}

const ZodiacResult = std.meta.Tuple(&[_]type{[]const u8} ** 7);

fn ceToChineseZodiac(ce_year: u14) ZodiacResult {
    const celestial_pinyin = [10][]const u8{
        "jiă", "yĭ",   "bĭng", "dīng", "wù",
        "jĭ",  "gēng", "xīn",  "rén",  "gŭi",
    };
    const celestial = [10][]const u8{
        "甲", "乙", "丙", "丁", "戊",
        "己", "庚", "辛", "壬", "癸",
    };
    const terrestrial = [12][]const u8{
        "子", "丑", "寅", "卯", "辰", "巳",
        "午", "未", "申", "酉", "戌", "亥",
    };
    const terrestrial_pinyin = [12][]const u8{
        "zĭ", "chŏu", "yín",  "măo", "chén", "sì",
        "wŭ", "wèi",  "shēn", "yŏu", "xū",   "hài",
    };
    const animals = [12][]const u8{
        "Rat",   "Ox",   "Tiger",  "Rabbit",  "Dragon", "Snake",
        "Horse", "Goat", "Monkey", "Rooster", "Dog",    "Pig",
    };
    const elements = [5][]const u8{ "Wood", "Fire", "Earth", "Metal", "Water" };
    const aspects = [2][]const u8{ "yang", "yin" };

    const BASE = 4;

    const cycle_year = ce_year - BASE;
    const aspect = aspects[cycle_year % 2];
    const stem_number = cycle_year % 10;
    const element = elements[stem_number / 2];
    const stem_han = celestial[stem_number];
    const stem_pinyin = celestial_pinyin[stem_number];

    const branch_number = cycle_year % 12;
    const animal = animals[branch_number];
    const branch_han = terrestrial[branch_number];
    const branch_pinyin = terrestrial_pinyin[branch_number];

    return ZodiacResult{ stem_han, branch_han, stem_pinyin, branch_pinyin, element, animal, aspect };
}
