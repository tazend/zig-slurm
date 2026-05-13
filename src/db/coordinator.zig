const std = @import("std");
const common = @import("../common.zig");
const CStr = common.CStr;

pub const Coordinator = extern struct {
    name: ?CStr = null,
    direct: u16 = 0,
};
