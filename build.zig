const std = @import("std");
const Builder = @import("std").build.Builder;

const examples = &[_][]const u8{"amp", "fifths", "params"};

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    inline for (examples) |example, i| {
        const lib = b.addSharedLibrary(example, "examples/" ++ example ++ "/" ++ example ++ ".zig", .{ .unversioned = {} });

        lib.addPackagePath("lv2", "src/lv2.zig");
        lib.setBuildMode(mode);
        lib.setOutputDir("zig-out/" ++ example ++ ".lv2");
        lib.linkLibC();
        lib.addIncludeDir("lv2");
        
        var step = b.step(example, "Build example \"" ++ example ++ "\"");
        step.dependOn(&b.addInstallFileWithDir("examples/" ++ example ++ "/" ++ example ++ ".ttl", .Prefix, example ++ ".lv2/manifest.ttl").step);
        step.dependOn(&lib.step);
    }
}
