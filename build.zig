const std = @import("std");
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    const lib = b.addSharedLibrary("example", "examples/example.zig", .{ .unversioned = {} });

    lib.addPackagePath("lv2", "lv2.zig");
    lib.setBuildMode(mode);
    lib.install();

    lib.setOutputDir("zig-cache/example.lv2");

    lib.linkLibC();
    lib.addIncludeDir("lv2");
    
    b.installFile("examples/example.ttl", "example.lv2/manifest.ttl");
}
