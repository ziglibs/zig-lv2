const c = @import("c.zig");
const std = @import("std");

pub const Map = struct {
    map_internal: ?*c.LV2_URID_Map = null,

    pub fn fromData(data: *c_void) Map {
        return Map{
            .map_internal = @ptrCast(*c.LV2_URID_Map, @alignCast(@alignOf(*c.LV2_URID_Map), data))
        };
    }

    pub fn map(self: *@This(), uri: []const u8) u32 {
        return self.map_internal.?.map.?(self.map_internal.?.handle, @ptrCast([*c]const u8, uri));
    }
};

pub const Logger = struct {
    logger_internal: c.LV2_Log_Logger,

    pub fn applyData(self: @This(), data: *c_void) void {
        self.logger_internal.log = @ptrCast(*c.LV2_Log_Log, data);
    }
};

pub const Feature = enum {
    map,

    pub fn toURI(self: @This()) []const u8 {
        return switch (self) {
            .map => "http://lv2plug.in/ns/ext/urid#map"
        };
    }
};

pub const FeatureData = union(enum) {
    map: *Map,

    pub fn fromData(feat: Feature, data: *c_void) FeatureData {
        switch (feat) {
            .map => return .{ .map = &Map.fromData(data) },
        }
    }
};

pub fn getFeatureData(features: []const c.LV2_Feature, uri: []const u8) ?*c_void {
    for (features) |filled_feat| {
        if (std.mem.eql(u8, uri, std.mem.span(filled_feat.URI))) {
            if (filled_feat.data) |dd| return dd;
        }
    }

    return null;
}

pub fn queryFeature(features: []const c.LV2_Feature, feat: Feature) ?FeatureData {
    return FeatureData.fromData(feat, getFeatureData(features, feat.toURI()) orelse return null);
}
