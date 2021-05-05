const c = @import("c.zig");
const std = @import("std");
const lv2 = @import("lv2.zig");

const StateStatus = extern enum(c_int) {
    state_success = 0,
    state_err_unknown = 1,
    state_err_bad_type = 2,
    state_err_bad_flags = 3,
    state_err_no_feature = 4,
    state_err_no_property = 5,
    state_err_no_space = 6,
    _,
};

pub fn StateMap(comptime State: type) type {
    var fields: [std.meta.fields(State).len]std.builtin.TypeInfo.StructField = undefined;
    
    for (std.meta.fields(State)) |field, i| {
        fields[i] = .{
            .name = field.name,
            .field_type = u32,
            .default_value = null,
            .is_comptime = false,
            .alignment = @alignOf(u32),
        };
    }

    return @Type(.{
        .Struct = .{
            .layout = .Auto,
            .fields = &fields,
            .decls = &[_]std.builtin.TypeInfo.Declaration{},
            .is_tuple = false,
        }
    });
}

pub fn StateManager(comptime State: type) type {
    var SM = StateMap(State);
    return struct {
        const Self = @This();

        state: State,
        state_urid_map: SM,
        state_type_map: SM,

        pub fn map(self: *Self, comptime uri: []const u8, map_: lv2.Map) void {
            inline for (std.meta.fields(State)) |field| {
                @field(self.state_urid_map, field.name) = map_.map(uri ++ "#" ++ field.name);
            }
        }

        pub fn extensionData(uri: []const u8) ?*c_void {
            if (std.mem.eql(u8, uri, lv2.c.LV2_STATE__interface)) {
                var state = lv2.c.LV2_State_Interface{
                    .save = Self.save,
                    .restore = Self.restore
                };
                return @ptrCast(*c_void, &state);
            } else return null;
        }
        
        // State save method.
        // This is used in the usual way when called by the host to save plugin state,
        // but also internally for writing messages in the audio thread by passing a
        // "store" function which actually writes the description to the forge.
        pub fn save (handle: lv2.c.LV2_Handle, store: lv2.c.LV2_State_Store_Function, state_handle: lv2.c.LV2_State_Handle, flags: u32, features: [*c]const [*c]const lv2.c.LV2_Feature) callconv(.C) lv2.c.LV2_State_Status {
            if (store == null) return @intToEnum(lv2.c.LV2_State_Status, 0);

            var state = @ptrCast(*State, @alignCast(@alignOf(*State), state_handle));
            var map_path = lv2.getFeatureData(@ptrCast(*const []lv2.c.LV2_Feature, features).*, lv2.c.LV2_STATE__mapPath).?;

            var status = @intToEnum(lv2.c.LV2_State_Status, 0);

            inline for (std.meta.fields(State)) |field| {
                var value = @field(state, field.name);
                var key = @field(@fieldParentPtr(Self, "state", state).state_urid_map, field.name);
                var t = @field(@fieldParentPtr(Self, "state", state).state_type_map, field.name);

                status = store.?(handle, key, @ptrCast(*c_void, &value.body), value.atom.size, t, lv2.c.LV2_STATE_IS_POD | lv2.c.LV2_STATE_IS_PORTABLE);
            }

            return status;
        }

        pub fn restore (handle: lv2.c.LV2_Handle, ret: lv2.c.LV2_State_Retrieve_Function, state: lv2.c.LV2_State_Handle, flags: u32, features: [*c]const [*c]const lv2.c.LV2_Feature) callconv(.C) lv2.c.LV2_State_Status {
            return @intToEnum(lv2.c.LV2_State_Status, 0);
        }
    };
}
