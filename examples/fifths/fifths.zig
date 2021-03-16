const std = @import("std");
const lv2 = @import("lv2");

pub const FifthsURIs = struct {
    atom_path: u32,
    atom_resource: u32,
    atom_sequence: u32,
    atom_urid: u32,
    atom_event_transfer: u32,
    midi_event: u32,
    patch_set: u32,
    patch_property: u32,
    patch_value: u32,

    pub fn map(self: *@This(), map_: *lv2.Map) void {
        self.atom_path = map_.map(lv2.c.LV2_ATOM__Path);
        self.atom_resource = map_.map(lv2.c.LV2_ATOM__Resource);
        self.atom_sequence = map_.map(lv2.c.LV2_ATOM__Sequence);
        self.atom_urid = map_.map(lv2.c.LV2_ATOM__URID);
        self.atom_event_transfer = map_.map(lv2.c.LV2_ATOM__eventTransfer);
        self.midi_event = map_.map(lv2.c.LV2_MIDI__MidiEvent);
        self.patch_set = map_.map(lv2.c.LV2_PATCH__Set);
        self.patch_property = map_.map(lv2.c.LV2_PATCH__property);
        self.patch_value = map_.map(lv2.c.LV2_PATCH__value);
    }
};

pub const Fifths = lv2.Plugin{
    .uri = "http://augustera.me/fifths",
    .Handle = struct {
        in: lv2.c.LV2_Atom_Sequence,
        out: lv2.c.LV2_Atom_Sequence,

        map: *lv2.Map,
        uris: FifthsURIs
    },
};

comptime {
    Fifths.exportPlugin(.{
        .instantiate = instantiate,
        .run = run
    });
}

fn instantiate (
    handle: *Fifths.Handle,
    descriptor: *const lv2.c.LV2_Descriptor,
    rate: f64,
    bundle_path: []const u8,
    features: []const lv2.c.LV2_Feature
) anyerror!void {
    handle.map = lv2.queryFeature(features, .map).?.map;

    handle.uris.map(handle.map);
}

fn run(handle: *Fifths.Handle, samples: u32) void {
    // var iter: *lv2.c.LV2_Atom_Event = lv2.atomSequenceBegin(&handle.in.body);
    // while (!lv2.atomSequenceEnded(&handle.in.body, handle.in.atom.size, iter)) : (iter = lv2.atomSequenceNext(iter)) {
    //     std.debug.print("{}\n", .{iter});
    // }
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    var f = std.fs.cwd().createFile("C:/Users/augus/Documents/Programming/Plugins/lv2fun/log.a", .{}) catch unreachable;
    f.writeAll(msg) catch {};
    f.close();
    std.process.exit(1);
}
