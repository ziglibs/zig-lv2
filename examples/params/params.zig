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
    patch_subject: u32,
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
        self.patch_subject = map_.map(lv2.c.LV2_PATCH__subject);
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
        map: *lv2.URIDMap,
        unmap: *lv2.URIDUnmap,
        forge: lv2.AtomForge,

        // URIs
        uris: URIs,

        // State
        state_manager: StateManager
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
    handle.map = features.query(lv2.URIDMap).?;
    handle.unmap = features.query(lv2.URIDUnmap).?;
    handle.forge.init(handle.map);

    handle.uris.map(handle.map);
    handle.state_manager.map(Params.uri, handle.map);
}

fn activate(handle: *Params.Handle) void {
}

fn deactivate(handle: *Params.Handle) void {
    // debug_file.close();
}

fn log(comptime f: []const u8, a: anytype) void {
    var debug_file = std.fs.cwd().createFile("C:/Programming/Zig/zig-lv2/log.b", .{}) catch {std.os.exit(1);};
    debug_file.writer().print(f, a) catch {};
}

fn run(handle: *Params.Handle, samples: u32) void {
    handle.forge.setBuffer(handle.out.toBuffer(), handle.out.atom.size);
    
    var out_frame = std.mem.zeroes(lv2.AtomForgeFrame);
    _ = handle.forge.writeSequenceHead(&out_frame, 0);

    var iter = handle.in.iterator();
    while (iter.next()) |event| {
        @panic("B");
        // var obj = event.toAtomObject();
        // if (obj.body.kind == handle.uris.patch_set) {
        //     var subject: ?*lv2.AtomURID = null;
        //     var property: ?*lv2.AtomURID = null;
        //     var value: ?*lv2.Atom = null;

        //     obj.query(&[_]lv2.AtomObjectQuery{
        //         .{ .key = handle.uris.patch_subject, .value = @ptrCast(*?*lv2.Atom, &subject) },
        //         .{ .key = handle.uris.patch_property, .value = @ptrCast(*?*lv2.Atom, &property) },
        //         .{ .key = handle.uris.patch_value, .value = &value }
        //     });

        //     handle.state_manager.setParameter(property.?.body, value.?);
        // }
    }

    handle.forge.pop(&out_frame);
    // @panic("Empty");
}

fn extensionData(uri: []const u8) ?*c_void {
    if (StateManager.extensionData(uri)) |ext| return ext;
    return null;
}

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace) noreturn {
    var debug_file = std.fs.cwd().createFile("C:/Programming/Zig/zig-lv2/log.a", .{}) catch {std.os.exit(1);};
    debug_file.writer().writeAll(msg) catch {};
    
    const debug_info = std.debug.getSelfDebugInfo() catch |err| {
        debug_file.writer().print("Unable to dump stack trace: Unable to open debug info: {s}\n", .{@errorName(err)}) catch std.process.exit(1);
        std.process.exit(1);
    };
    std.debug.writeCurrentStackTrace(debug_file.writer(), std.debug.getSelfDebugInfo() catch std.os.exit(1), std.debug.detectTTYConfig(), @returnAddress()) catch |err| {
        debug_file.writer().print("Unable to dump stack trace: {s}\n", .{@errorName(err)}) catch std.process.exit(1);
        std.process.exit(1);
    };
    
    std.process.exit(1);
}
