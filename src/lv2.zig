const std = @import("std");
pub const c = @import("c.zig");

pub usingnamespace @import("urid.zig");
pub usingnamespace @import("atom.zig");
pub usingnamespace @import("utils.zig");

pub const Descriptor = c.LV2_Descriptor;

pub fn Handlers(comptime Handle_: type) type {
    return struct {
        run: ?fn (handle: *Handle_, samples: u32) void = null,
        instantiate: ?fn (handle: *Handle_, descriptor: *const Descriptor, rate: f64, bundle_path: []const u8, features: Features) anyerror!void = null,
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

            fn toHandle(instance: c.LV2_Handle) *Handle__ {
                return @ptrCast(*Handle__, @alignCast(@alignOf(*Handle__), instance));
            }

            pub fn instantiate(descriptor: [*c]const Descriptor, rate: f64, bundle_path: [*c]const u8, features: [*c]const [*c]const c.LV2_Feature) callconv(.C) c.LV2_Handle {
                var handle = std.heap.c_allocator.create(Handle__) catch {
                    std.debug.print("Yeah you're kinda screwed!", .{});
                    std.os.exit(1);
                };
                
                if (handlers.instantiate) |act| act(handle, @ptrCast(*const Descriptor, descriptor), rate, std.mem.span(bundle_path), Features.init(@ptrCast(*const []c.LV2_Feature, features).*)) catch {
                    std.heap.c_allocator.destroy(handle);
                    std.os.exit(1);
                };

                return @ptrCast(c.LV2_Handle, handle);
            }

            pub fn cleanup(instance: c.LV2_Handle) callconv(.C) void {
                std.heap.c_allocator.destroy(toHandle(instance));
            }

            pub fn connect_port(instance: c.LV2_Handle, port: u32, data: ?*c_void) callconv(.C) void {
                var hnd = toHandle(instance);

                inline for (std.meta.fields(@TypeOf(hnd.*))) |field, i| {
                    if (i == port) {
                        if (@typeInfo(field.field_type) != .Pointer) {
                            if (@hasDecl(field.field_type, "connectPort")) @field(@field(hnd, field.name), "connectPort")(data);
                        } else {
                            @field(hnd, field.name) = @ptrCast(field.field_type, @alignCast(@alignOf(field.field_type), data));
                        }
                    }
                }
            }

            pub fn activate(instance: c.LV2_Handle) callconv(.C) void {
                if (handlers.activate) |act| act(toHandle(instance));
            }

            pub fn deactivate(instance: c.LV2_Handle) callconv(.C) void {
                if (handlers.deactivate) |deact| deact(toHandle(instance));
            }

            pub fn extension_data(uri: [*c]const u8) callconv(.C) ?*c_void {
                if (handlers.extensionData) |rn| return rn(uri);
                return null;
            }

            pub fn run(instance: c.LV2_Handle, n_samples: u32) callconv(.C) void {
                if (handlers.run) |rn| rn(toHandle(instance), n_samples);
            }

            pub const __globalDescriptor = Descriptor{ .URI = URI_.ptr, .instantiate = instantiate, .connect_port = connect_port, .activate = activate, .run = run, .deactivate = deactivate, .cleanup = cleanup, .extension_data = extension_data };

            pub fn lv2_descriptor(index: u32) callconv(.C) [*c]const Descriptor {
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
