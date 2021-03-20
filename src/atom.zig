const c = @import("c.zig");
const std = @import("std");

pub const AtomSequence = struct {
    const Self = @This();

    seq_internal: *c.LV2_Atom_Sequence,

    pub fn connectPort(self: *Self, maybeData: ?*c_void) void {
        if (maybeData) |data| {
            self.seq_internal = @ptrCast(*c.LV2_Atom_Sequence, @alignCast(@alignOf(c.LV2_Atom_Sequence), data));
        }
    }

    pub fn iterator(self: Self) AtomSequenceIterator {
        return AtomSequenceIterator.init(self.seq_internal);
    }
};

fn atomPadSize(size: u32) u32 {
    return (size + @as(u32, 7)) & (~@as(u32, 7));
}

fn atomSequenceEnd(body: *c.LV2_Atom_Sequence_Body, size: u32) *c.LV2_Atom_Event {
    return @intToPtr(*c.LV2_Atom_Event, @ptrToInt(body) + atomPadSize(size));
}

fn atomSequenceBegin(body: *c.LV2_Atom_Sequence_Body) *c.LV2_Atom_Event {
    return @intToPtr(*c.LV2_Atom_Event, @ptrToInt(body) + 8);
}

fn atomSequenceNext(event: *c.LV2_Atom_Event) *c.LV2_Atom_Event {
    return @intToPtr(*c.LV2_Atom_Event, @ptrToInt(event) + @sizeOf(c.LV2_Atom_Event) + atomPadSize(event.body.size));
}

fn atomSequenceEnded(body: *c.LV2_Atom_Sequence_Body, size: u32, i: *c.LV2_Atom_Event) bool {
    return @ptrToInt(i) >= (@ptrToInt(body) + size);
}

pub fn atomSequenceClear(seq: *c.LV2_Atom_Sequence) void {
    seq.atom.size = @sizeOf(c.LV2_Atom_Sequence_Body);
}

pub fn atomSequenceAppendEvent(seq: *c.LV2_Atom_Sequence, capacity: u32, event: *c.LV2_Atom_Event) ?*c.LV2_Atom_Event {
    var total_size = @sizeOf(@TypeOf(event)) + event.body.size;
    if (capacity - seq.atom.size < total_size) {
        return null;
    }

    var e = atomSequenceEnd(&seq.body, seq.atom.size);
    @memcpy(@ptrCast([*]align(8) u8, e), @ptrCast([*]align(8) u8, event), total_size);

    seq.atom.size += atomPadSize(total_size);

    return e;
}

pub const AtomSequenceIterator = struct {
    const Self = @This();

    seq: *c.LV2_Atom_Sequence,
    last: *c.LV2_Atom_Event,

    pub fn init(seq: *c.LV2_Atom_Sequence) AtomSequenceIterator {
        return Self{
            .seq = seq,
            .last = atomSequenceBegin(&seq.body)
        };
    }

    pub fn next(self: *Self) ?*c.LV2_Atom_Event {
        self.last = atomSequenceNext(self.last);
        return if (!atomSequenceEnded(&self.seq.body, self.seq.atom.size, self.last)) self.last else null;
    }
};
