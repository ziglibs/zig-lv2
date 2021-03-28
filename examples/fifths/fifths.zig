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
        in: lv2.AtomSequence,
        out: lv2.AtomSequence,

        map: *lv2.Map,
        uris: FifthsURIs
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
    handle.map = lv2.queryFeature(features, .map).?.map;

    handle.uris.map(handle.map);
}

const MidiNoteData = struct {
    status: u8,
    pitch: u8,
    velocity: u8
};

const MidiNoteEvent = struct {
    event: lv2.c.LV2_Atom_Event,
    data: MidiNoteData
};

fn run(handle: *Fifths.Handle, samples: u32) void {
    const out_size = handle.out.seq_internal.atom.size;
    
    handle.out.clear();
    handle.out.seq_internal.atom.@"type" = handle.in.seq_internal.atom.@"type";

    var iter = handle.in.iterator();
    while (iter.next()) |*event| {
        if (event.event_internal.body.@"type" == handle.uris.midi_event) {
            _ = handle.out.appendEvent(out_size, event.*) catch @panic("Error appending!");

            var data = event.getDataAs(*MidiNoteData);
            var fifth = std.mem.zeroes(MidiNoteEvent);
            var ev = event.event_internal;

            fifth.event.time.frames = ev.time.frames;
            fifth.event.body.@"type" = ev.body.@"type";
            fifth.event.body.size = ev.body.size;
            fifth.data.status = data.status;
            fifth.data.pitch = data.pitch + 7;
            fifth.data.velocity = data.velocity;

            _ = handle.out.appendEvent(out_size, lv2.AtomEvent.init(&fifth.event)) catch @panic("Error appending!");
        }
    }
}
