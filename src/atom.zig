const c = @import("c.zig");
const std = @import("std");

pub const AtomEvent = struct {
    const Self = @This();

    event_internal: *c.LV2_Atom_Event,

    pub fn init(event: *c.LV2_Atom_Event) Self {
        return Self{
            .event_internal = event
        };
    }

    pub fn getDataAs(self: *Self, comptime T: type) T {
        return @intToPtr(T, @ptrToInt(self.event_internal) + @sizeOf(c.LV2_Atom_Event));
    }
};

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

    pub fn appendEvent(self: Self, out_size: u32, event: AtomEvent) !AtomEvent {
        var maybe_appended_event = c.lv2_atom_sequence_append_event(self.seq_internal, out_size, event.event_internal);
        return if (maybe_appended_event) |appended_event| AtomEvent.init(appended_event) else error.AppendError;
    }
};

pub const AtomSequenceIterator = struct {
    const Self = @This();

    seq: *c.LV2_Atom_Sequence,
    last: ?*c.LV2_Atom_Event,

    pub fn init(seq: *c.LV2_Atom_Sequence) Self {
        return Self{
            .seq = seq,
            .last = null
        };
    }

    pub fn next(self: *Self) ?AtomEvent {
        self.last = if (self.last) |last| c.lv2_atom_sequence_next(last) else c.lv2_atom_sequence_begin(&self.seq.body);
        if (c.lv2_atom_sequence_is_end(&self.seq.body, self.seq.atom.size, self.last)) return null;
        return if (self.last) |l| AtomEvent.init(l) else null;
    }
};
