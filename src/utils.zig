const c = @import("c.zig");
const std = @import("std");

pub const Logger = struct {
    logger_internal: c.LV2_Log_Logger,

    pub fn applyData(self: @This(), data: *c_void) void {
        self.logger_internal.log = @ptrCast(*c.LV2_Log_Log, data);
    }
};

pub const Features = struct {
    const Self = @This();

    features: []const c.LV2_Feature,

    pub fn init(features: []const c.LV2_Feature) Self {
        return Self{
            .features = features
        };
    }

    pub fn query(self: Self, comptime T: type) ?*T {
        return queryFeature(self.features, T);
    }
};

pub fn getFeatureData(features: []const c.LV2_Feature, uri: []const u8) ?*c_void {
    for (features) |filled_feat| {
        if (filled_feat.URI != null and std.mem.eql(u8, uri, std.mem.span(filled_feat.URI))) {
            if (filled_feat.data) |dd| return dd;
        }
    }

    return null;
}

pub fn queryFeature(features: []const c.LV2_Feature, comptime T: type) ?*T {
    return @field(T, "fromData")(getFeatureData(features, @field(T, "toURI")()) orelse return null);
}
