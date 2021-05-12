const c = @import("c.zig");

pub const URID = u32;

pub const MapHandle = ?*c_void;
pub const UnmapHandle = ?*c_void;

pub const URIDMap = extern struct {
    const Self = @This();

    handle: MapHandle,
    map_: ?fn (MapHandle, [*c]const u8) callconv(.C) URID,

    pub fn fromData(data: *c_void) *Self {
        return @ptrCast(*Self, @alignCast(@alignOf(*Self), data));
    }

    pub fn toURI() []const u8 {
        return "http://lv2plug.in/ns/ext/urid#map";
    }

    pub fn map(self: Self, uri: []const u8) u32 {
        return self.map_.?(self.handle, @ptrCast([*c]const u8, uri));        
    }
};

pub const URIDUnmap = extern struct {
    const Self = @This();

    handle: UnmapHandle,
    unmap_: ?fn (UnmapHandle, URID) callconv(.C) [*c]const u8,

    pub fn fromData(data: *c_void) *Self {
        return @ptrCast(*Self, @alignCast(@alignOf(*Self), data));
    }

    pub fn toURI() []const u8 {
        return "http://lv2plug.in/ns/ext/urid#unmap";
    }

    pub fn unmap(self: Self, mapped: u32) []const u8 {
        return self.unmap_.?(self.handle, mapped);        
    }
};
