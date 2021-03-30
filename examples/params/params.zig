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

// pub const State = struct {
//     aint:      LV2_Atom_Int,
//     along:     LV2_Atom_Long,
//     afloat:    LV2_Atom_Float,
//     adouble:   LV2_Atom_Double,
//     abool:     LV2_Atom_Bool,
//     astring:   LV2_Atom,
//     string:    [1024]u8,
//     apath:     LV2_Atom,
//     path:      [1024]u8,
//     lfo:       LV2_Atom_Float,
//     spring:    LV2_Atom_Float
// };

pub const Fifths = lv2.Plugin{
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
        // state: State
    },
};

comptime {
    Fifths.exportPlugin(.{
        .instantiate = instantiate,
        .run = run,
    });
}

fn instantiate (
    handle: *Fifths.Handle,
    descriptor: *const lv2.c.LV2_Descriptor,
    rate: f64,
    bundle_path: []const u8,
    features: []const lv2.c.LV2_Feature
) anyerror!void {
    handle.map = lv2.queryFeature(features, lv2.Map).?;
    handle.unmap = lv2.queryFeature(features, lv2.Unmap).?;

    handle.uris.map(handle.map);
}

fn run(handle: *Fifths.Handle, samples: u32) void {
    
}
