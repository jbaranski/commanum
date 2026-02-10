const std = @import("std");

pub fn build(b: *std.Build) void {
    const commanum_mod = b.createModule(.{
        .root_source_file = b.path("../zig/src/commanum.zig"),
        .target = b.graph.host,
    });

    const exe = b.addExecutable(.{
        .name = "tps",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = b.graph.host,
            .imports = &.{
                .{ .name = "commanum", .module = commanum_mod },
            },
        }),
    });

    b.installArtifact(exe);
}
