const c = @import("../c.zig");
const std = @import("std");
const urid = @import("../urid.zig");

pub const Atom = extern struct {
    const Self = @This();
    
    size: urid.URID,
    kind: urid.URID
};

pub const AtomObjectBody = extern struct {
    id: urid.URID,
    kind: urid.URID
};

pub const AtomPropertyBody = extern struct {
    const Self = @This();

    key: urid.URID,
    context: urid.URID,
    value: Atom,

    pub fn init(event: *c.LV2_Atom_Property_Body) *Self {
        return @ptrCast(*Self, event);
    }
};

pub const AtomObjectQuery = struct {
    key: urid.URID,
    value: *?*Atom
};

pub const AtomObject = extern struct {
    const Self = @This();

    atom: Atom,
    body: AtomObjectBody,

    pub fn iterator(self: *Self) AtomObjectIterator {
        return AtomObjectIterator.init(@ptrCast(*c.LV2_Atom_Object, self));
    }

    pub fn query(self: *Self, queries: []AtomObjectQuery) void {
        var it = self.iterator();
        while (it.next()) |prop| {
            for (queries) |q| {
                if (prop.key == q.key and q.value.* == null) {
                    q.value.* = &prop.value;
                    break;
                }
            }
        }
    }
};

pub const AtomObjectIterator = struct {
    const Self = @This();

    object: *c.LV2_Atom_Object,
    last: ?*c.LV2_Atom_Property_Body,

    pub fn init(object: *c.LV2_Atom_Object) Self {
        return Self{
            .object = object,
            .last = null
        };
    }

    pub fn next(self: *Self) ?*AtomPropertyBody {
        self.last = if (self.last) |last| c.lv2_atom_object_next(last) else c.lv2_atom_object_begin(&self.object.body);
        if (c.lv2_atom_object_is_end(&self.object.body, self.object.atom.size, self.last)) return null;
        return if (self.last) |l| AtomPropertyBody.init(l) else null;
    }
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

    pub fn toAtomObject(self: *Self) *AtomObject {
        return @ptrCast(*AtomObject, &self.body);
    }
};

pub const AtomSequenceBody = extern struct {
    /// URID of unit of event time stamps
    unit: urid.URID,
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

    pub fn toBuffer(self: *Self) [*c]u8 {
        return @ptrCast([*c]u8, self);
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

pub fn AtomOf(comptime T: type, atom_type: []const u8) type {
    return extern struct {
        pub const __atom_type = atom_type;

        atom: Atom,
        body: T
    };
}

pub const AtomInt = AtomOf(i32, c.LV2_ATOM__Int);
pub const AtomLong = AtomOf(i64, c.LV2_ATOM__Long);
pub const AtomFloat = AtomOf(f32, c.LV2_ATOM__Float);
pub const AtomDouble = AtomOf(f64, c.LV2_ATOM__Double);
pub const AtomBool = AtomOf(bool, c.LV2_ATOM__Bool);
pub const AtomURID = AtomOf(u32, c.LV2_ATOM__URID);
pub const AtomString = AtomOf([*:0]const u8, c.LV2_ATOM__String);
pub const AtomPath = AtomOf([*:0]const u8, c.LV2_ATOM__Path);
