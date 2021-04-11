const c = @import("c.zig");

pub const Map = struct {
    const Self = @This();
    
    map_internal: ?*c.LV2_URID_Map = null,

    pub fn fromData(data: *c_void) Self {
        return Self{
            .map_internal = @ptrCast(*c.LV2_URID_Map, @alignCast(@alignOf(*c.LV2_URID_Map), data))
        };
    }

    pub fn toURI() []const u8 {
        return "http://lv2plug.in/ns/ext/urid#map";
    }

    pub fn map(self: Self, uri: []const u8) u32 {
        return self.map_internal.?.map.?(self.map_internal.?.handle, @ptrCast([*c]const u8, uri));
    }
};

pub const Unmap = struct {
    const Self = @This();

    unmap_internal: ?*c.LV2_URID_Unmap = null,

    pub fn fromData(data: *c_void) Self {
        return Self{
            .unmap_internal = @ptrCast(*c.LV2_URID_Unmap, @alignCast(@alignOf(*c.LV2_URID_Unmap), data))
        };
    }

    pub fn toURI() []const u8 {
        return "http://lv2plug.in/ns/ext/urid#unmap";
    }

    pub fn unmap(self: Self, mapped: u32) []const u8 {
        return self.unmap_internal.?.unmap.?(self.unmap_internal.?.handle, @ptrCast([*c]const u8, mapped));
    }
};

