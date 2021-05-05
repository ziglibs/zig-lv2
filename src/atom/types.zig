const c = @import("../c.zig");
usingnamespace @import("atom.zig");

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
