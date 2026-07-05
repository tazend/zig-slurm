const std = @import("std");
const Compile = std.Build.Step.Compile;
const log = std.log.scoped(.build);

const PathType = enum {
    library,
    include,
};

fn accessSubDir(handle: *std.fs.Dir, prefix: []const u8, sub_path: []const u8) bool {
    handle.access(sub_path, .{}) catch |err| switch(err) {
        error.FileNotFound => return false,
        else => |e| {
            log.err("cannot access dir: {s}/{s}: {t}", .{ prefix, sub_path, e});
            std.process.exit(1);
        },
    };
    return true;
}

fn openPrefixDir(handle: *std.fs.Dir, path: []const u8) std.fs.Dir {
    const dir = handle.openDir(path, .{}) catch |err| {
        log.err("cannot open prefix dir: {s}: {t}", .{path, err});
        std.process.exit(1);
    };
    return dir;
}

fn addPath(b: *std.Build, target: *Compile, dir: *std.fs.Dir, prefix: []const u8, sub_dir: []const u8, path_type: PathType) void {
    if (accessSubDir(dir, prefix, sub_dir)) {
        const p: std.Build.LazyPath = .{ .cwd_relative = prefix };
        const path = p.join(b.allocator, sub_dir) catch @panic("OOM");

        switch (path_type) {
            .library => target.root_module.addLibraryPath(path),
            .include => target.root_module.addIncludePath(path),
        }
    }
}

fn processPrefix(b: *std.Build, target: *Compile, prefix: []const u8) void {
    var dir = openPrefixDir(&b.build_root.handle, prefix);
    defer dir.close();
    addPath(b, target, &dir, prefix, "include", .include);
    addPath(b, target, &dir, prefix, "lib64", .library);
    addPath(b, target, &dir, prefix, "lib64/slurm", .library);
    addPath(b, target, &dir, prefix, "lib/slurm", .library);
}

pub fn setupSlurmPath(b: *std.Build, target: *Compile) !void {
    for (b.search_prefixes.items) |o| {
        processPrefix(b, target, o);
    }
    // Some common default include and library dirs for slurm
    processPrefix(b, target, "/");
    processPrefix(b, target, "/usr");
}

pub fn readSlurmVersionFile(b: *std.Build, target: *Compile) !std.SemanticVersion {
    for (target.root_module.include_dirs.items) |i| {
        const slurm_version_h = try i.path.join(b.allocator, "slurm/slurm_version.h");
        const text = b.build_root.handle.readFileAlloc(b.allocator, slurm_version_h.getPath(b), 64 * 1024) catch |err| switch(err) {
           error.FileNotFound => continue,
           else => return err,
        };

        const needle = "#define SLURM_VERSION_NUMBER ";
        var itr = std.mem.splitScalar(u8, text, '\n');
        while (itr.next())  |line| {
            if (!std.mem.startsWith(u8, line, needle)) continue;
            const ver_str = std.mem.trimStart(u8, line, needle);
            const ver = try std.fmt.parseInt(usize, ver_str, 0);
            return .{
                .major = (ver >> 16) & 0xff,
                .minor = (ver >> 8) & 0xff,
                .patch = ver & 0xff,
            };
        }
    }
    return .{
        .major = 0,
        .minor = 0,
        .patch = 0,
    };
}

fn parseVersion(gpa: std.mem.Allocator, text: []const u8) !std.SemanticVersion {
    const fmt = if (std.mem.count(u8, text, ".") == 1)
        try std.fmt.allocPrint(gpa, "{s}.0", .{text})
    else
        text;
    return .parse(fmt);
}

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const use_slurmfull = b.option(bool, "use-slurmfull", "Whether to use libslurmfull.so or not.") orelse false;
    const version: ?[]const u8 = b.option([]const u8, "version", "Which version of slurm to target") orelse null;
    const bindgen_opt: bool = b.option(bool, "bindgen", "Detect that bindgen will be run.") orelse false;

    const config = b.addOptions();

    var slurm_mod = b.addModule("slurm", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const slurm_lib = b.addLibrary(.{
        .name = "slurm",
        .root_module = slurm_mod,
    });
    const slurm_lib_name = if (use_slurmfull) "slurmfull" else "slurm";
    slurm_lib.root_module.linkSystemLibrary(slurm_lib_name, .{});

    try setupSlurmPath(b, slurm_lib);

    const semver: std.SemanticVersion = if (version) |v|
        try parseVersion(b.allocator, v)
    else
        try readSlurmVersionFile(b, slurm_lib);

    const root_file = try std.fmt.allocPrint(b.allocator, "src/version/{d}.{d}/root.zig", .{semver.major, semver.minor});
    slurm_mod.root_source_file = b.path(root_file);

    // This does not work with an optional. It forgets to bring in std. Bug?
    config.addOption(std.SemanticVersion, "slurm_version", semver);
    slurm_mod.addOptions("config", config);

    b.installArtifact(slurm_lib);

    if (bindgen_opt) {
        const bindgen = b.dependency("bindgen", .{
            .target = target,
            .optimize = optimize,
        });
        const run_bindgen = b.addRunArtifact(bindgen.artifact("zig_slurm_bindgen"));
        const bindgen_step = b.step("bindgen", "Run bindgen");
        if (b.args) |args| {
            run_bindgen.addArgs(args);
        }
        bindgen_step.dependOn(&run_bindgen.step);
    }

    const tests = b.addTest(.{
        .root_module = slurm_mod,
    });

    const run_unit_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run slurm tests");
    b.installArtifact(tests);
    test_step.dependOn(&run_unit_tests.step);

    const integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("test/root.zig"),
            .optimize = optimize,
            .target = target,
        }),
        .name = "test-integration",
    });

    integration_tests.root_module.addImport("slurm", slurm_mod);
    const run_integration_tests = b.addRunArtifact(integration_tests);
    const integration_test_step = b.step("test-integration", "Run integration tests");
    b.installArtifact(integration_tests);
    integration_test_step.dependOn(&run_integration_tests.step);
}
