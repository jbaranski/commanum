const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "commanum",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig/src/main.zig"),
            .target = b.graph.host,
        }),
    });

    b.installArtifact(exe);

    // Create commanum module for sharing
    const commanum_mod = b.createModule(.{
        .root_source_file = b.path("zig/src/main.zig"),
        .target = b.graph.host,
    });

    // Performance test executable
    const perf_test = b.addExecutable(.{
        .name = "perf_test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig/src/perf_test.zig"),
            .target = b.graph.host,
            .optimize = .ReleaseFast,
            .imports = &.{
                .{ .name = "commanum", .module = commanum_mod },
            },
        }),
    });

    b.installArtifact(perf_test);

    // Run step for perf test
    const run_perf = b.addRunArtifact(perf_test);
    const perf_step = b.step("perf", "Run the performance test");
    perf_step.dependOn(&run_perf.step);
}
