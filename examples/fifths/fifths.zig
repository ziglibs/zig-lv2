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

    pub fn map(self: *@This(), map_: *lv2.URIDMap) void {
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
        in: *lv2.AtomSequence,
        out: *lv2.AtomSequence,

        map: *lv2.URIDMap,
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
    descriptor: *const lv2.Descriptor,
    rate: f64,
    bundle_path: []const u8,
    features: lv2.Features
) anyerror!void {
    handle.map = features.query(lv2.URIDMap).?;

    handle.uris.map(handle.map);
}

const MidiNoteData = extern struct {
    status: u8,
    pitch: u8,
    velocity: u8
};

const MidiNoteEvent = extern struct {
    event: lv2.AtomEvent,
    data: MidiNoteData
};

fn run(handle: *Fifths.Handle, samples: u32) void {
    const out_size = handle.out.atom.size;
    handle.out.clear();
    handle.out.atom.kind = handle.in.atom.kind;

    var iter = handle.in.iterator();
    while (iter.next()) |event| {
        if (event.body.kind == handle.uris.midi_event) {
            _ = handle.out.appendEvent(out_size, event) catch @panic("Error appending!");

            var data = event.getDataAs(*MidiNoteData);
            var fifth = std.mem.zeroes(MidiNoteEvent);

            fifth.event.time.frames = event.time.frames;
            fifth.event.body.kind = event.body.kind;
            fifth.event.body.size = event.body.size;

            fifth.data.status = data.status;
            fifth.data.pitch = data.pitch + 7;
            fifth.data.velocity = data.velocity;

            _ = handle.out.appendEvent(out_size, &fifth.event) catch @panic("Error appending!");
        }
    }
}
