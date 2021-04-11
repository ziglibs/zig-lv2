const c = @import("c.zig");

const StateStatus = extern enum(c_int) {
    state_success = 0,
    state_err_unknown = 1,
    state_err_bad_type = 2,
    state_err_bad_flags = 3,
    state_err_no_feature = 4,
    state_err_no_property = 5,
    state_err_no_space = 6,
    _,
};

pub const State = {

};
