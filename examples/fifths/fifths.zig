const std = @import("std");
const lv2 = @import("lv2");

pub const Fifths = lv2.Plugin{
    .uri = "http://augustera.me/fifths",
    .Handle = struct {
        input: [*]f32,
        gain: *f32,
        output: [*]f32
    },
};

comptime {
    Fifths.exportPlugin(.{
        .instantiate = instantiate,
        .run = run
    });
}

// TODO: Remove all public use of C code
fn instantiate (
    handle: *Fifths.Handle,
    descriptor: *const lv2.c.LV2_Descriptor,
    rate: f64,
    bundle_path: []const u8,
    features: []const lv2.c.LV2_Feature
) anyerror!void {
    var feat = lv2.queryMissingFeature(features, &[_]lv2.Feature{
        .{
            .uri = "http://lv2plug.in/ns/ext/log#log",
            .required = false
        },
        .{
            .uri = "http://lv2plug.in/ns/ext/urid#map",
            .required = true
        }
    });

    if (feat) |_| return error.MissingFeature;
}

fn run(handle: *Fifths.Handle, samples: u32) void {
    
}
