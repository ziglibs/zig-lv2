usingnamespace @import("atom.zig");

pub fn AtomOf(comptime T: type) type {
    return extern struct {
        atom: Atom,
        body: T
    };
}

pub const AtomInt = AtomOf(i32);
pub const AtomLong = AtomOf(i64);
pub const AtomFloat = AtomOf(f32);
pub const AtomDouble = AtomOf(f64);
pub const AtomBool = AtomOf(bool);
pub const AtomURID = AtomOf(u32);
pub const AtomString = AtomOf([*:0]const u8);
pub const AtomPath = AtomString;
