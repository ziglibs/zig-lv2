const std = @import("std");
const lv2 = @import("lv2");

pub const LV2Fun = lv2.Plugin{
    .uri = "http://augustera.me/example",
    .Handle = struct {
        input: [*]f32,
        gain: *f32,
        output: [*]f32
    },
};

comptime {
    LV2Fun.exportPlugin(.{
        .run = run
    });
}

fn decibelsToCoeff(g: f32) f32 {
    return if (g > -90) std.math.pow(f32, 10, g * 0.05) else 0;
}

fn run(handle: *LV2Fun.Handle, samples: u32) void {
    const coef = decibelsToCoeff(handle.gain.*);
    
    var i: usize = 0;
    while (i < samples) : (i += 1) {
        handle.output[i] = handle.input[i] * coef;
    }
}
