const std = @import("std");
const Io = std.Io;
const Translator = @import("translate_c").Translator;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const source_files = try getFiles(b, ".");

    const all = b.step("all", "Build/Install all rosettacode examples");
    const tests = b.step("test", "Run all tests");

    // --------------------------------------------------------------
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    // --------------------------------------------------------------
    const csvzero = b.dependency("csvzero", .{});
    const primesieve = b.dependency("primesieve", .{});
    const raylib = b.dependency("raylib", .{
        .raudio = true,
        .rmodels = true,
        .rshapes = true,
        .rtext = true,
        .rtextures = true,
    });

    // --------------------------------------------------------------
    const translate_c = b.dependency("translate_c", .{});

    const translator: Translator = .init(translate_c, .{
        .c_source_file = b.path("c.h"),
        .target = target,
        .optimize = optimize,
        // additional options now available that go here:
        // https://codeberg.org/ziglang/translate-c#options
    });

    // --------------------------------------------------------------
    for (source_files) |si| {
        defer _ = arena.reset(.retain_capacity);
        const task: Task, const flags: Flags = try evaluateTask(b.graph.io, arena_allocator, si);
        switch (task) {
            .discard => continue,
            .test_only,
            .vanilla_c,
            .isaac_cypher,
            .zig,
            => {},
        }

        const root_module = b.createModule(.{
            .root_source_file = b.path(si.path),
            .target = target,
            .optimize = optimize,
        });

        // ----------------------------- link libraries / C files
        switch (task) {
            .vanilla_c => {
                root_module.link_libc = true;
                root_module.addImport("c", translator.mod);
            },
            .isaac_cypher => {
                root_module.link_libc = true;
                root_module.addCSourceFile(.{ .file = b.path("The_ISAAC_cipher.c") });
            },
            .test_only => {},
            .zig => {
                if (flags.csvzero_flag) root_module.addImport("csvzero", csvzero.module("csvzero"));
                if (flags.primesieve_flag) root_module.addImport("primesieve", primesieve.module("primesieve"));
                if (flags.raylib_flag) root_module.addImport("raylib", raylib.module("raylib"));
            },
            .discard => unreachable,
        }

        // ------------------------------------------- executable
        if (task != .test_only) {
            const exe = b.addExecutable(.{
                .name = si.name,
                .root_module = root_module,
            });

            const run_step = b.step(si.name, si.name);

            const install_cmd = b.addInstallArtifact(exe, .{});

            const run_cmd = b.addRunArtifact(exe);
            run_cmd.cwd = b.path(si.module_subpath);
            run_cmd.step.dependOn(&install_cmd.step);

            run_step.dependOn(&run_cmd.step);
            all.dependOn(&install_cmd.step);
        }
        // ------------------------------------------------ tests
        if (flags.test_flag) {
            const exe_tests = b.addTest(.{
                .root_module = root_module,
            });
            const run_exe_tests = b.addRunArtifact(exe_tests);
            tests.dependOn(&run_exe_tests.step);
        }
        // ------------------------------------------------------
    }
}

const SourceInfo = struct {
    path: []const u8,
    name: []const u8,
    module_subpath: []const u8,
};

fn getFiles(b: *std.Build, module_subpath: []const u8) ![]const SourceInfo {
    var result: std.ArrayList(SourceInfo) = .empty;

    const io: Io = b.graph.io;

    var dir = try Io.Dir.cwd().openDir(io, b.pathResolve(&.{ ".", module_subpath }), .{ .iterate = true });
    defer dir.close(io);

    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        if (entry.name[0] == '.')
            continue;
        switch (entry.kind) {
            .file => {
                if (std.mem.startsWith(u8, entry.name, "build.zig")) continue;
            },
            .directory => {
                if (std.mem.eql(u8, entry.name, "zig-out")) continue;
                if (std.mem.eql(u8, entry.name, "zig-pkg")) continue;
                const files = try getFiles(b, b.pathJoin(&.{ module_subpath, entry.name }));
                defer b.allocator.free(files);
                try result.appendSlice(b.allocator, files);
            },
            else => continue,
        }
        const extension_idx = std.mem.lastIndexOf(u8, entry.name, ".zig") orelse continue;
        if (std.mem.indexOf(u8, entry.name, "build.") == 0) continue;

        const name = entry.name[0..extension_idx];
        if (std.mem.indexOf(u8, name, "TODO") != null) {
            std.log.info("TODO   {s}", .{name});
            continue;
        }
        const path = b.pathJoin(&.{ module_subpath, entry.name });

        try result.append(b.allocator, .{
            .name = try b.allocator.dupe(u8, name),
            .path = try b.allocator.dupe(u8, path),
            .module_subpath = try b.allocator.dupe(u8, module_subpath),
        });
    }
    return result.toOwnedSlice(b.allocator);
}

const Task = enum {
    discard,
    vanilla_c,
    isaac_cypher,
    zig,
    test_only, // no main(), only tests
};

const Flags = struct {
    csvzero_flag: bool = false,
    primesieve_flag: bool = false,
    raylib_flag: bool = false,
    test_flag: bool = false,
};

fn evaluateTask(io: Io, allocator: std.mem.Allocator, source_info: SourceInfo) !struct { Task, Flags } {
    var flags: Flags = .{};
    // std.debug.print("{s}\n{s}\n{s}\n\n", .{ source_info.module_subpath, source_info.name, source_info.path });
    const f = try Io.Dir.cwd().openFile(io, source_info.path, .{});
    defer f.close(io);

    var buffer: [4096]u8 = undefined;
    var file_reader = f.reader(io, &buffer);
    const r = &file_reader.interface;
    const text = try r.allocRemaining(allocator, .unlimited);

    flags.test_flag = std.mem.indexOf(u8, text, "\ntest ") != null;

    if (std.mem.indexOf(u8, text, "This file should fail to compile") != null) {
        std.log.info("@CompileLog() {s}", .{source_info.name});
        return .{ .discard, flags };
    }

    if (std.mem.indexOf(u8, text, "{{works with|Zig|0.14.1}}") != null) {
        std.log.info("0.14.1 {s}", .{source_info.name});
        return .{ .discard, flags };
    }
    if (std.mem.indexOf(u8, text, "{{works with|Zig|0.15.1}}") != null) {
        // std.log.info("0.15.1 {s}", .{source_info.name});
        return .{ .discard, flags };
    }
    if (std.mem.indexOf(u8, text, "{{works with|Zig|0.15.2}}") != null) {
        std.log.info("0.15.2 {s}", .{source_info.name});
        return .{ .discard, flags };
    }
    if (std.mem.indexOf(u8, text, "{{works with|Zig|0.16.0}}") != null) {
        std.log.info("0.16.0 {s}", .{source_info.name});
        return .{ .discard, flags };
    }

    // Expected to be zig 0.17.0
    if (std.mem.indexOf(u8, text, "{works with|Zig|0.17.0}}") == null) {
        std.log.warn("Expected Zig 0.17.0 - not found {s}", .{source_info.path});
        return .{ .discard, .{} };
    }

    flags.csvzero_flag = (std.mem.indexOf(u8, text, "= @import(\"csvzero\");") != null);
    flags.primesieve_flag = (std.mem.indexOf(u8, text, "= @import(\"primesieve\");") != null);
    flags.raylib_flag = (std.mem.indexOf(u8, text, "= @import(\"raylib\");") != null);

    if (std.mem.indexOf(u8, text, "\npub fn main(") == null) {
        if (flags.test_flag) {
            std.log.info("no main() {s}", .{source_info.name});
            return .{ .test_only, flags };
        } else {
            std.log.info("--------- no main, no test --------- {s}", .{source_info.name});
            return .{ .discard, .{} };
        }
    }

    if (std.mem.indexOf(u8, text, "The_ISAAC_cipher") != null) {
        // std.log.info("ISAAC  {s}", .{source_info.name});
        return .{ .isaac_cypher, .{} };
    }
    if (std.mem.indexOf(u8, text, "@import(\"c\")") != null or std.mem.indexOf(u8, text, "extern fn ") != null) {
        // std.log.info("C      {s}", .{source_info.name});
        return .{ .vanilla_c, flags };
    }

    return .{ .zig, flags };
}
