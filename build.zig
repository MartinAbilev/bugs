const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl");
const imgui = @import("src/deps/imgui/build.zig");
const zaudio = @import("src/deps/zaudio/build.zig");
const stb = @import("src/deps/stb/build.zig");
const svg = @import("src/deps/svg/build.zig");
const zmath = @import("src/deps/zmath/build.zig");
const zmesh = @import("src/deps/zmesh/build.zig");
const znoise = @import("src/deps/znoise/build.zig");
const cp = @import("src/deps/chipmunk//build.zig");
const nfd = @import("src/deps/nfd/build.zig");
const ztracy = @import("src/deps/ztracy/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const assets_install = b.addInstallDirectory(.{
        .source_dir = .{ .cwd_relative = "assets" },
        .install_dir = .bin,
        .install_subdir = "assets",
    });
    const examples = [_]struct { name: []const u8, opt: BuildOptions }
    {
        .{ .name = "bugz", .opt = .{ .use_cp = true } },
    };

    const build_examples = b.step("examples", "compile and install all examples");

    inline for (examples) |demo|
    {
        const exe = createGame(
            b,
            demo.name,
            "src/main.zig",
            target,
            optimize,
            demo.opt,
        );
        const install_cmd = b.addInstallArtifact(exe, .{});
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&install_cmd.step);
        run_cmd.step.dependOn(&assets_install.step);
        run_cmd.cwd = std.Build.LazyPath{ .cwd_relative = "zig-out/bin" };
        const run_step = b.step(
            demo.name,
            "run example " ++ demo.name,
        );
        run_step.dependOn(&run_cmd.step);
        build_examples.dependOn(&install_cmd.step);
    }
}

pub const BuildOptions = struct {
    use_cp: bool = false,
    use_nfd: bool = false,
    use_ztracy: bool = false,
    enable_ztracy: bool = false,
};

/// Create game executable
pub fn createGame(
    b: *std.Build,
    name: []const u8,
    root_file: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
    opt: BuildOptions,
) *std.Build.Step.Compile {
    // Initialize jok module
    const bos = b.addOptions();
    bos.addOption(bool, "use_cp", opt.use_cp);
    bos.addOption(bool, "use_nfd", opt.use_nfd);
    bos.addOption(bool, "use_ztracy", opt.use_ztracy);
    const sdl_sdk = sdl.init(b, null);
    const zaudio_pkg = zaudio.package(b, target, optimize, .{});
    const zmath_pkg = zmath.package(b, target, optimize, .{});
    const zmesh_pkg = zmesh.package(b, target, optimize, .{});
    const znoise_pkg = znoise.package(b, target, optimize, .{});
    const ztracy_pkg = ztracy.package(b, target, optimize, .{
        .options = .{ .enable_ztracy = opt.enable_ztracy },
    });
    const jok = b.createModule(.{
        .root_source_file = .{ .cwd_relative = thisDir() ++ "/src/jok.zig" },
        .imports = &.{
            .{ .name = "build_options", .module = bos.createModule() },
            .{ .name = "sdl", .module = sdl_sdk.getWrapperModule() },
            .{ .name = "zgui", .module = imgui.getZguiModule(b, target, optimize) },
            .{ .name = "zaudio", .module = zaudio_pkg.zaudio },
            .{ .name = "zmath", .module = zmath_pkg.zmath },
            .{ .name = "zmesh", .module = zmesh_pkg.zmesh },
            .{ .name = "znoise", .module = znoise_pkg.znoise },
        },
    });

    const tokamak = b.dependency("tokamak", .{}).module("tokamak");

    if (opt.use_ztracy) {
        jok.import_table.putNoClobber(b.allocator, "ztracy", ztracy_pkg.ztracy) catch unreachable;
    }

    // Initialize executable
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = .{ .cwd_relative = thisDir() ++ "/src/app.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("jok", jok);
    exe.root_module.addImport("tokamak", b.dependency("tokamak", .{}).module("tokamak"));

    exe.root_module.addImport("game", b.createModule(.{
        .root_source_file = .{ .cwd_relative = root_file },
        .imports = &.{
            .{ .name = "jok", .module = jok },
            .{ .name = "tokamak", .module = tokamak },
        },
    }));

    // Link libraries
    sdl_sdk.link(exe, .dynamic);
    imgui.link(b, exe);
    stb.link(exe);
    svg.link(exe);
    zaudio_pkg.link(exe);
    zmesh_pkg.link(exe);
    znoise_pkg.link(exe);

    cp.link(exe);

    if (opt.use_nfd) {
        nfd.link(exe);
    }
    if (opt.use_ztracy) {
        ztracy_pkg.link(exe);
    }

    return exe;
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
