const c = @import("../c.zig");
const std = @import("std");
const atom = @import("atom.zig");
const urid = @import("../urid.zig");

pub const AtomForgeSinkHandle = ?*c_void;
pub const AtomForgeRef = isize;
pub const AtomForgeSink = ?fn (sink_handle: AtomForgeSinkHandle, buf: ?*const c_void, size: u32) callconv(.C) AtomForgeRef;
pub const AtomForgeDerefFunc = ?fn (sink_handle: AtomForgeSinkHandle, ref: AtomForgeRef) callconv(.C) [*c]atom.Atom;

pub const AtomForgeFrame = extern struct {
    parent: [*c]AtomForgeFrame,
    ref: AtomForgeRef
};

/// TODO: Actually zigify this so it isn't a total mess
pub const AtomForge = extern struct {
    const Self = @This();

    buf: [*c]u8,
    offset: u32,
    size: u32,
    /// Function that writes output to sink.
    sink: AtomForgeSink,
    deref_func: AtomForgeDerefFunc,
    /// The handle to the output sink.
    sink_handle: AtomForgeSinkHandle,
    stack: [*c]AtomForgeFrame,

    /// Deprecated
    Blank: urid.URID,
    Bool: urid.URID,
    Chunk: urid.URID,
    Double: urid.URID,
    Float: urid.URID,
    Int: urid.URID,
    Long: urid.URID,
    Literal: urid.URID,
    Object: urid.URID,
    Path: urid.URID,
    Property: urid.URID,
    /// Deprecated
    Resource: urid.URID,
    Sequence: urid.URID,
    String: urid.URID,
    Tuple: urid.URID,
    URI: urid.URID,
    URID: urid.URID,
    Vector: urid.URID,

    /// Initalize self.
    pub fn init(self: *Self, map: *urid.URIDMap) void {
        self.setBuffer(null, 0);
        self.Blank = map.map(c.LV2_ATOM__Blank);
        self.Bool = map.map(c.LV2_ATOM__Bool);
        self.Chunk = map.map(c.LV2_ATOM__Chunk);
        self.Double = map.map(c.LV2_ATOM__Double);
        self.Float = map.map(c.LV2_ATOM__Float);
        self.Int = map.map(c.LV2_ATOM__Int);
        self.Long = map.map(c.LV2_ATOM__Long);
        self.Literal = map.map(c.LV2_ATOM__Literal);
        self.Object = map.map(c.LV2_ATOM__Object);
        self.Path = map.map(c.LV2_ATOM__Path);
        self.Property = map.map(c.LV2_ATOM__Property);
        self.Resource = map.map(c.LV2_ATOM__Resource);
        self.Sequence = map.map(c.LV2_ATOM__Sequence);
        self.String = map.map(c.LV2_ATOM__String);
        self.Tuple = map.map(c.LV2_ATOM__Tuple);
        self.URI = map.map(c.LV2_ATOM__URI);
        self.URID = map.map(c.LV2_ATOM__URID);
        self.Vector = map.map(c.LV2_ATOM__Vector);
    }
    
    /// Access the Atom pointed to by a reference.
    pub fn deref(self: *Self, ref: AtomForgeRef) *atom.Atom {
        if (ref < 0) @panic("huh");
        return if (self.buf != null) @intToPtr(*atom.Atom, std.math.absCast(ref)) else self.deref_func.?(self.sink_handle, ref);
    }

    /// Push a stack frame. Automatically handled by container functions.
    pub fn push(self: *Self, frame: *AtomForgeFrame, ref: AtomForgeRef) AtomForgeRef {
        frame.parent = self.stack;
        frame.ref = ref;

        if (ref != 0) {
            self.stack = frame;
        }

        return ref;
    }

    /// Pop a stack frame. This must be called when a container is finished.
    pub fn pop(self: *Self, frame: *AtomForgeFrame) void {
        if (frame.ref != 0) {
            std.debug.assert(frame == self.stack);
            self.stack = frame.parent;
        }
    }

    /// Return true if the top of the stack is the given kind.
    pub fn topIs(self: *Self, kind: urid.URID) bool {
        return 
            self.stack != null and
            self.stack.ref != 0 and
            self.deref(self.stack.ref).kind == kind;
    }

    /// Return true if `kind` is an atom:Object
    pub fn isObjectKind(self: *Self, kind: urid.URID) bool {
        return kind == self.Object or kind == self.Blank or kind == self.Resource;
    }

    /// Return true if `type` is an atom:Object with a blank ID.
    pub fn isBlank(self: *Self, kind: urid.URID, body: *atom.AtomObjectBody) bool {
        return kind == self.Blank or (kind == self.Object and body.id == 0); 
    }

    /// Set forge buffer.
    pub fn setBuffer(self: *Self, buf: [*c]u8, size: usize) void {
        self.buf = buf;
        self.size = @truncate(u32, size);
        self.offset = 0;
        self.deref_func = null;
        self.sink = null;
        self.sink_handle = null;
        self.stack = null;
    }

    /// Set forge sink.
    pub fn setSink(self: *Self, sink: AtomForgeSink, deref: AtomForgeDerefFunc, sink_handle: AtomForgeSinkHandle) void {
        self.buf = null;
        self.size = 0;
        self.offset = 0;

        self.deref_func = deref;
        self.sink = sink;
        self.sink_handle = sink_handle;
    }

    /// Writes raw output.
    pub fn raw(self: *Self, data: ?*const c_void, size: u32) AtomForgeRef {
        var out: AtomForgeRef = 0;
        
        if (self.sink) |sink| {
            out = sink(self.sink_handle, data, size);
        } else {
            out = @intCast(AtomForgeRef, @ptrToInt(self.buf)) + @bitCast(c_longlong, @as(c_ulonglong, self.offset));
            var mem: *u8 = self.buf + self.offset;
            if (self.offset + size > self.size) {
                return 0;
            }
            self.offset += size;
            _ = c.memcpy(@ptrCast(?*c_void, mem), data, @bitCast(c_ulonglong, @as(c_ulonglong, size)));
            // @memcpy(@ptrCast([*]u8, @ptrCast(?*c_void, mem)), @ptrCast([*]const u8, data.?), @bitCast(c_ulonglong, @as(c_ulonglong, size)));
        }

        if (self.stack != null)  {
            self.deref(self.stack.*.parent.*.ref).size += size;
        }
        
        return out;
    }

    /// Pad so next write is 64-bit aligned.
    pub fn pad(self: *Self, written: u32) void {
        const pad_: u64 = 0;
        var pad_size: u32 = c.lv2_atom_pad_size(written) - written;
        _ = self.raw(@ptrCast(?*const c_void, &pad_), pad_size);
    }

    /// `raw` but with padding.
    pub fn write(self: *Self, data: ?*const c_void, size: u32) AtomForgeRef {
        var out = self.raw(data, size);
        if (out != 0) {
            self.pad(size);
        }
        return out;
    }

    /// Write a null-terminated string body.
    pub fn stringBody(self: *Self, str: []const u8, len: u32) AtomForgeRef {
        var out = self.raw(@ptrCast(?*const c_void, str), len);
        if (out and o: {
            out = self.raw(@ptrCast(?*const c_void, ""), 1);
            break :o out;
        }) {
            self.pad(len + 1);
        }
        return out;
    }

    pub fn writeAtom(self: *Self, size: u32, kind: urid.URID) AtomForgeRef {
        const at = atom.Atom{
            .size = size,
            .kind = kind
        };
        return self.raw(@ptrCast(?*const c_void, &at), @truncate(u32, @sizeOf(at)));
    }

    pub fn writeAtomPrimitive(self: *Self, at: *atom.Atom) AtomForgeRef {
        return if (self.topIs(self.Vector)) self.raw(@ptrCast(?*const c_void, @ptrCast([*c]const u8, @alignCast(@import("std").meta.alignment(u8), at)) + @sizeOf(atom.Atom)), at.size) else self.write(@ptrCast(?*c_void, at), @truncate(u32, @sizeOf(at)) + at.size);
    }

    fn writeAtomOfType(self: *Self, comptime T: type, value: T, kind: urid.URID) AtomForgeRef {
        var at = atom.AtomInt{
            .atom = .{
                .size = @sizeOf(value),
                .kind = kind
            },
            .body = value
        };
        return self.writeAtomPrimitive(&at.atom);
    }

    pub fn writeAtomInt(self: *Self, value: i32) AtomForgeRef {
        return self.writeAtomOfType(i32, value, self.Int);
    }

    pub fn writeAtomLong(self: *Self, value: i64) AtomForgeRef {
        return self.writeAtomOfType(i64, value, self.Long);
    }

    pub fn writeAtomFloat(self: *Self, value: f32) AtomForgeRef {
        return self.writeAtomOfType(f32, value, self.Float);
    }

    pub fn writeAtomDouble(self: *Self, value: f64) AtomForgeRef {
        return self.writeAtomOfType(f64, value, self.Double);
    }

    pub fn writeAtomBool(self: *Self, value: bool) AtomForgeRef {
        return self.writeAtomOfType(bool, value, self.Bool);
    }

    pub fn writeAtomURID(self: *Self, value: urid.URID) AtomForgeRef {
        return self.writeAtomOfType(urid.URID, value, self.URID);
    }

    pub fn writeSequenceHead(self: *Self, frame: *AtomForgeFrame, unit: u32) AtomForgeRef {
        var seq = atom.AtomSequence{
            .atom = .{
                // .size = @as(u32, @sizeOf(atom.AtomSequenceBody)),
                .size = @bitCast(u32, @truncate(c_uint, @sizeOf(atom.AtomSequenceBody))),
                .kind = self.Sequence
            },
            .body = .{
                .unit = unit,
                .pad = 0
            }
        };
        return self.push(frame, self.write(@ptrCast(?*const c_void, &seq), @bitCast(u32, @truncate(c_uint, @sizeOf(atom.AtomSequence)))));
        // return self.push(frame, self.write(@ptrCast(?*const c_void, &seq), @sizeOf(atom.AtomSequence)));
    }
};


