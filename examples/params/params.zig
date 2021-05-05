const std = @import("std");
const lv2 = @import("lv2");

pub const URIs = struct {
    atom_path: u32,
    atom_resource: u32,
    atom_sequence: u32,
    atom_urid: u32,
    atom_event_transfer: u32,
    midi_event: u32,
    patch_set: u32,
    patch_property: u32,
    patch_value: u32,

    pub fn map(self: *@This(), map_: lv2.Map) void {
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

pub const StateManager = lv2.StateManager(struct {
    aint:      lv2.AtomInt,
    along:     lv2.AtomLong,
    afloat:    lv2.AtomFloat,
    adouble:   lv2.AtomDouble,
    abool:     lv2.AtomBool,
    astring:   lv2.AtomString,
    apath:     lv2.AtomPath,
    lfo:       lv2.AtomFloat,
    spring:    lv2.AtomFloat
});

pub const Params = lv2.Plugin{
    .uri = "http://augustera.me/params",
    .Handle = struct {
        // Ports
        in: *lv2.AtomSequence,
        out: *lv2.AtomSequence,

        // Features
        map: lv2.Map,
        unmap: lv2.Unmap,

        // URIs
        uris: URIs,

        // State
        state_manager: StateManager,

        debug_file: std.fs.File
    },
};

comptime {
    Params.exportPlugin(.{
        .instantiate = instantiate,
        .run = run,
        .activate = activate,
        .deactivate = deactivate,
        .extensionData = extensionData
    });
}

fn instantiate (
    handle: *Params.Handle,
    descriptor: *const lv2.Descriptor,
    rate: f64,
    bundle_path: []const u8,
    features: lv2.Features
) anyerror!void {
    handle.map = features.query(lv2.Map).?;
    handle.unmap = features.query(lv2.Unmap).?;

    handle.uris.map(handle.map);
    handle.state_manager.map(Params.uri, handle.map);
}

fn activate(handle: *Params.Handle) void {
    handle.debug_file = std.fs.cwd().createFile("C:/Programming/Zig/zig-lv2/log.a", .{}) catch {std.os.exit(1);};
}

fn deactivate(handle: *Params.Handle) void {
    handle.debug_file.close();
}

fn run(handle: *Params.Handle, samples: u32) void {
    var iter = handle.in.iterator();
    while (iter.next()) |event| {
        var object = event.toAtomObject();
        if (object.body.otype == handle.uris.patch_set) {
            handle.debug_file.writer().print("{}\n", .{object}) catch {};
        }
    }
}

fn extensionData(uri: []const u8) ?*c_void {
    if (StateManager.extensionData(uri)) |ext| return ext;
    return null;
}
