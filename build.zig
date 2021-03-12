const std = @import("std");
const Builder = @import("std").build.Builder;

const examples = &[_][]const u8{"amp", "fifths"};

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    inline for (examples) |example, i| {
        const lib = b.addSharedLibrary(example, "examples/" ++ example ++ "/" ++ example ++ ".zig", .{ .unversioned = {} });

        lib.addPackagePath("lv2", "src/lv2.zig");
        lib.setBuildMode(mode);
        lib.setOutputDir("zig-cache/" ++ example ++ ".lv2");
        lib.linkLibC();
        lib.addIncludeDir("lv2");
        
        b.step(example, "Build example \"" ++ example ++ "\"").dependOn(&lib.step);
        b.installFile("examples/" ++ example ++ "/" ++ example ++ ".ttl", example ++ ".lv2/manifest.ttl");
    }
}
