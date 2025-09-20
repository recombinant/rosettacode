// https://rosettacode.org/wiki/Vigen%C3%A8re_cipher/Cryptanalysis
// {{works with|Zig|0.15.1}}
// {{trans|C++}}
const std = @import("std");

pub fn main() !void {
    const input =
        \\ MOMUD EKAPV TQEFM OEVHP AJMII CDCTI FGYAG JSPXY ALUYM NSMYH
        \\ VUXJE LEPXJ FXGCM JHKDZ RYICU HYPUS PGIGM OIYHF WHTCQ KMLRD
        \\ ITLXZ LJFVQ GHOLW CUHLO MDSOE KTALU VYLNZ RFGBX PHVGA LWQIS
        \\ FGRPH JOOFW GUBYI LAPLA LCAFA AMKLG CETDW VOELJ IKGJB XPHVG
        \\ ALWQC SNWBU BYHCU HKOCE XJEYK BQKVY KIIEH GRLGH XEOLW AWFOJ
        \\ ILOVV RHPKD WIHKN ATUHN VRYAQ DIVHX FHRZV QWMWV LGSHN NLVZS
        \\ JLAKI FHXUF XJLXM TBLQV RXXHR FZXGV LRAJI EXPRV OSMNP KEPDT
        \\ LPRWM JAZPK LQUZA ALGZX GVLKL GJTUI ITDSU REZXJ ERXZS HMPST
        \\ MTEOE PAPJH SMFNB YVQUZ AALGA YDNMP AQOWT UHDBV TSMUE UIMVH
        \\ QGVRW AEFSP EMPVE PKXZY WLKJA GWALT VYYOB YIXOK IHPDS EVLEV
        \\ RVSGB JOGYW FHKBL GLXYA MVKIS KIEHY IMAPX UOISK PVAGN MZHPW
        \\ TTZPV XFCCD TUHJH WLAPF YULTB UXJLN SIJVV YOVDJ SOLXG TGRVO
        \\ SFRII CTMKO JFCQF KTINQ BWVHG TENLH HOGCS PSFPV GJOKM SIFPR
        \\ ZPAAS ATPTZ FTPPD PORRF TAXZP KALQA WMIUD BWNCT LEFKO ZQDLX
        \\ BUXJL ASIMR PNMBF ZCYLV WAPVF QRHZV ZGZEF KBYIO OFXYE VOWGB
        \\ BXVCB XBAWG LQKCM ICRRX MACUO IKHQU AJEGL OIJHH XPVZW JEWBA
        \\ FWAML ZZRXJ EKAHV FASMU LVVUT TGK
    ;
    const english = [26]f64{
        0.08167, 0.01492, 0.02782, 0.04253, 0.12702, 0.02228,
        0.02015, 0.06094, 0.06966, 0.00153, 0.00772, 0.04025,
        0.02406, 0.06749, 0.07507, 0.01929, 0.00095, 0.05987,
        0.06327, 0.09056, 0.02758, 0.00978, 0.02360, 0.00150,
        0.01974, 0.00074,
    };

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var va: VigenereAnalyser = .init(english);
    const output = try va.analyze(allocator, input);
    defer {
        allocator.free(output.text);
        allocator.free(output.key);
    }

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.print("Key: {s}\n\n", .{output.key});
    try stdout.print("Text: {s}\n", .{output.text});
    try stdout.flush();
}

const Pair = struct {
    c: u8,
    frequency: f64,

    fn asc(_: void, a: Pair, b: Pair) bool {
        return a.frequency < b.frequency;
    }
    fn desc(_: void, a: Pair, b: Pair) bool {
        return a.frequency > b.frequency;
    }
};
const FrequencyArray = [26]Pair;

const VigenereAnalyser = struct {
    const Self = @This();
    targets: [26]f64,
    sorted_targets: [26]f64,
    freq: FrequencyArray = undefined,

    fn init(target_frequencies: [26]f64) VigenereAnalyser {
        var sorted_targets = target_frequencies;
        std.mem.sortUnstable(f64, &sorted_targets, {}, std.sort.asc(f64));
        return VigenereAnalyser{
            .targets = target_frequencies,
            .sorted_targets = sorted_targets,
        };
    }

    /// Caller owns the two returned strings - but not the struct itself.
    fn analyze(self: *Self, allocator: std.mem.Allocator, input: []const u8) !struct { text: []const u8, key: []const u8 } {
        const cleaned = blk: {
            var cleaned: std.ArrayList(u8) = .empty;
            for (input) |c|
                if (std.ascii.isAlphabetic(c))
                    try cleaned.append(allocator, std.ascii.toUpper(c));
            break :blk try cleaned.toOwnedSlice(allocator);
        };
        defer allocator.free(cleaned);

        const best_length = blk: {
            var best_length: usize = 0;
            var best_corr: f64 = -100.0;

            // Assume that if there are less than 20 characters
            // per column, the key's too long to guess
            for (2..cleaned.len / 20) |i| {
                var pieces = try createStringArray(allocator, i);
                defer deinitStringArray(allocator, pieces);

                for (cleaned, 0..) |c, j|
                    try pieces[j % i].append(allocator, c);

                // The correlation increases artificially for smaller
                // pieces/longer keys, so weigh against them a little
                var corr: f64 = -0.5 * @as(f64, @floatFromInt(i));
                for (pieces) |piece|
                    corr += self.correlation(piece.items);

                if (corr > best_corr) {
                    best_length = i;
                    best_corr = corr;
                }
            }
            break :blk best_length;
        };

        if (best_length == 0)
            return .{
                .text = try allocator.dupe(u8, "Text is too short to analyze"),
                .key = try allocator.dupe(u8, ""),
            };

        const pieces = blk: {
            var pieces = try createStringArray(allocator, best_length);
            for (cleaned, 0..) |c, i|
                try pieces[i % best_length].append(allocator, c);
            break :blk pieces;
        };
        defer deinitStringArray(allocator, pieces);

        const freqs = blk: {
            var freqs: std.ArrayList(FrequencyArray) = .empty;
            for (0..best_length) |i|
                try freqs.append(allocator, self.updateFreq(pieces[i].items));
            break :blk try freqs.toOwnedSlice(allocator);
        };
        defer allocator.free(freqs);

        const key: []const u8 = blk: {
            var key: std.ArrayList(u8) = .empty;
            for (0..best_length) |i| {
                std.mem.sortUnstable(Pair, &freqs[i], {}, Pair.desc);

                var m: u8 = 0;
                var m_corr: f64 = 0.0;
                var j: u8 = 0;
                while (j < 26) : (j += 1) {
                    var corr: f64 = 0.0;
                    const c = 'A' + j;
                    for (freqs[i]) |pair| {
                        const d: u8 = (pair.c + 26 - c) % 26;
                        corr += pair.frequency * self.targets[d];
                    }
                    if (corr > m_corr) {
                        m = j;
                        m_corr = corr;
                    }
                }
                try key.append(allocator, m + 'A');
            }
            break :blk try key.toOwnedSlice(allocator);
        };

        var result: std.ArrayList(u8) = .empty;
        for (cleaned, 0..) |c, i|
            try result.append(allocator, (c + 26 - key[i % key.len]) % 26 + 'A');

        return .{ .text = try result.toOwnedSlice(allocator), .key = key };
    }

    fn updateFreq(self: *Self, input: []const u8) [26]Pair {
        for (self.freq[0..], 'A'..) |*freq, c|
            freq.* = .{ .c = @intCast(c), .frequency = 0 };

        for (input) |c|
            self.freq[c - 'A'].frequency += 1;

        return self.freq;
    }

    fn correlation(self: *Self, input: []const u8) f64 {
        var result: f64 = 0.0;
        _ = self.updateFreq(input);

        std.mem.sortUnstable(Pair, &self.freq, {}, Pair.asc);

        for (self.freq, &self.sorted_targets) |pair, target|
            result += pair.frequency * target;

        return result;
    }
};

fn createStringArray(allocator: std.mem.Allocator, size: usize) ![]std.ArrayList(u8) {
    var array: std.ArrayList(std.ArrayList(u8)) = try .initCapacity(allocator, size);
    for (0..size) |_|
        try array.append(allocator, .empty);
    return try array.toOwnedSlice(allocator);
}

fn deinitStringArray(allocator: std.mem.Allocator, array: []std.ArrayList(u8)) void {
    for (array) |*s|
        s.deinit(allocator);
    allocator.free(array);
}
