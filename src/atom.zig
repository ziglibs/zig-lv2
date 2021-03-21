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

    pub fn clear(self: Self) void {
        c.lv2_atom_sequence_clear(self.seq_internal);
    }

    pub fn appendEvent(self: Self, out_size: u32, event: *c.LV2_Atom_Event) ?*c.LV2_Atom_Event {
        return c.lv2_atom_sequence_append_event(self.seq_internal, out_size, event);
    }
};

pub const AtomSequenceIterator = struct {
    const Self = @This();

    seq: *c.LV2_Atom_Sequence,
    last: ?*c.LV2_Atom_Event,

    pub fn init(seq: *c.LV2_Atom_Sequence) AtomSequenceIterator {
        return Self{
            .seq = seq,
            .last = null
        };
    }

    pub fn next(self: *Self) ?*c.LV2_Atom_Event {
        self.last = if (self.last) |last| c.lv2_atom_sequence_next(last) else c.lv2_atom_sequence_begin(&self.seq.body);
        if (c.lv2_atom_sequence_is_end(&self.seq.body, self.seq.atom.size, self.last)) return null;
        return self.last;
    }
};
