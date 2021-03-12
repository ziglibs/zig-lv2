const std = @import("std");
const lv2 = @cImport({
    @cInclude("lv2/core/lv2.h");
});

pub fn Handlers(comptime Handle_: type) type {
    return struct {
        run: ?fn (handle: *Handle_, samples: u32) void = null,
        activate: ?fn (handle: *Handle_) void = null,
        deactivate: ?fn (handle: *Handle_) void = null,
        extensionData: ?fn(uri: []const u8) *c_void = null
    };
}

pub const Plugin = struct {
    uri: []const u8,
    Handle: type,

    pub fn exportPlugin(comptime self: Plugin, comptime handlers_: Handlers(self.Handle)) void {
        const lv = struct {
            const URI_ = self.uri;
            const handlers = handlers_;
            const Handle__ = self.Handle;

            fn toHandle(instance: lv2.LV2_Handle) *Handle__ {
                return @ptrCast(*Handle__, @alignCast(@alignOf(*Handle__), instance));
            }

            pub fn instantiate(descriptor: [*c]const lv2.LV2_Descriptor, rate: f64, bundle_path: [*c]const u8, features: [*c]const [*c]const lv2.LV2_Feature) callconv(.C) lv2.LV2_Handle {
                return @ptrCast(lv2.LV2_Handle, std.heap.c_allocator.create(Handle__) catch {
                    std.debug.print("Yeah you're kinda screwed!", .{});
                    std.os.exit(1);
                });
            }

            pub fn cleanup(instance: lv2.LV2_Handle) callconv(.C) void {
                std.heap.c_allocator.destroy(toHandle(instance));
            }

            pub fn connect_port(instance: lv2.LV2_Handle, port: u32, data: ?*c_void) callconv(.C) void {
                var hnd = toHandle(instance);

                inline for (std.meta.fields(@TypeOf(hnd.*))) |field, i| {
                    if (@typeInfo(field.field_type) != .Pointer) continue;
                    if (i == port) {
                        @field(hnd, field.name) = @ptrCast(field.field_type, @alignCast(@alignOf(field.field_type), data));
                    }
                }
            }

            pub fn activate(instance: lv2.LV2_Handle) callconv(.C) void {
                if (handlers.activate) |act| act(toHandle(instance));
            }

            pub fn deactivate(instance: lv2.LV2_Handle) callconv(.C) void {
                if (handlers.deactivate) |deact| deact(toHandle(instance));
            }

            pub fn extension_data(uri: [*c]const u8) callconv(.C) ?*c_void {
                if (handlers.extensionData) |rn| return rn(uri);
                return null;
            }

            pub fn run(instance: lv2.LV2_Handle, n_samples: u32) callconv(.C) void {
                if (handlers.run) |rn| rn(toHandle(instance), n_samples);
            }

            pub const __globalDescriptor = lv2.LV2_Descriptor{ .URI = URI_.ptr, .instantiate = instantiate, .connect_port = connect_port, .activate = activate, .run = run, .deactivate = deactivate, .cleanup = cleanup, .extension_data = extension_data };

            pub fn lv2_descriptor(index: u32) callconv(.C) [*c]const lv2.LV2_Descriptor {
                return if (index == 0) &__globalDescriptor else null;
            }
        };

        @export(lv.instantiate, .{ .name = "instantiate", .linkage = .Strong });
        @export(lv.connect_port, .{ .name = "connect_port", .linkage = .Strong });
        @export(lv.activate, .{ .name = "activate", .linkage = .Strong });
        @export(lv.run, .{ .name = "run", .linkage = .Strong });
        @export(lv.deactivate, .{ .name = "deactivate", .linkage = .Strong });
        @export(lv.cleanup, .{ .name = "cleanup", .linkage = .Strong });
        @export(lv.extension_data, .{ .name = "extension_data", .linkage = .Strong });
        @export(lv.lv2_descriptor, .{ .name = "lv2_descriptor", .linkage = .Strong });
    }
};
