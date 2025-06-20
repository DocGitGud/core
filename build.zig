const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    // -- Core Library
    const core_mod = b.addModule(.{
        .root_source_file = b.path("lib/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const core_lib = b.addStaticLibrary(.{
        .name = "core",
        .root_module = core_mod,
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(core_lib);
    // Core Library --

    // -- Core Tests
    const core_test_exe = b.addTest(.{
        .name = "core_tests",
        .root_source_file = b.path("lib/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_artifact = b.addRunArtifact(core_test_exe);
    const run_step = b.step("test", "Run 'Core' tests");
    run_step.dependOn(&run_artifact.step);
    // Core Tests --
}
