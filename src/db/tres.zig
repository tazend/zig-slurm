const common = @import("../common.zig");
const CStr = common.CStr;

pub const TrackableResource = extern struct {
    alloc_secs: u64 = 0,
    rec_count: u32 = 0,
    count: u64 = 0,
    id: u32 = 0,
    name: ?CStr = null,
    type: ?CStr = null,
};
