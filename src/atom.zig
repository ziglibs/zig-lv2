const c = @import("c.zig");
const std = @import("std");

pub const Atom = extern struct {
    const Self = @This();
    
    size: u32,
    kind: u32
};

pub const AtomEventTime = extern union {
    frames: i64,
    beats: f64,
};

pub const AtomEvent = extern struct {
    const Self = @This();

    time: AtomEventTime,
    body: Atom,

    pub fn init(event: *c.LV2_Atom_Event) *Self {
        return @ptrCast(*Self, event);
    }

    pub fn getDataAs(self: *Self, comptime T: type) T {
        return @intToPtr(T, @ptrToInt(self) + @sizeOf(Self));
    }
};

pub const AtomSequenceBody = extern struct {
    /// URID of unit of event time stamps
    unit: u32,
    /// Currently unused
    pad: u32,
};

pub const AtomSequence = extern struct {
    const Self = @This();

    atom: Atom,
    body: AtomSequenceBody,

    pub fn iterator(self: *Self) AtomSequenceIterator {
        return AtomSequenceIterator.init(@ptrCast(*c.LV2_Atom_Sequence, self));
    }

    pub fn clear(self: *Self) void {
        c.lv2_atom_sequence_clear(@ptrCast(*c.LV2_Atom_Sequence, self));
    }

    pub fn appendEvent(self: *Self, out_size: u32, event: *AtomEvent) !*AtomEvent {
        var maybe_appended_event = c.lv2_atom_sequence_append_event(@ptrCast(*c.LV2_Atom_Sequence, self), out_size, @ptrCast(*c.LV2_Atom_Event, event));
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

    pub fn next(self: *Self) ?*AtomEvent {
        self.last = if (self.last) |last| c.lv2_atom_sequence_next(last) else c.lv2_atom_sequence_begin(&self.seq.body);
        if (c.lv2_atom_sequence_is_end(&self.seq.body, self.seq.atom.size, self.last)) return null;
        return if (self.last) |l| AtomEvent.init(l) else null;
    }
};
