const std = @import("std");

pub fn build(b: *std.Build) !void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const add_paths = b.option(bool, "add-paths", "add macos SDK paths from dependency") orelse false;

    const objz = b.addModule("objz", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    if (add_paths) b.lazyImport(@This(), "zig-build-macos-sdk").?.addPathsModule(objz);
    objz.linkSystemLibrary("objc", .{});
    objz.linkFramework("Foundation", .{});

    const tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.linkSystemLibrary("objc");
    tests.linkFramework("Foundation");
    b.lazyImport(@This(), "zig-build-macos-sdk").?.addPaths(tests);

    const test_step = b.step("test", "Run tests");
    const tests_run = b.addRunArtifact(tests);
    test_step.dependOn(&tests_run.step);
}
