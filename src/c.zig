pub const c = @cImport({
    @cInclude("slurm/slurm.h");
    @cInclude("slurm/slurmdb.h");
    @cInclude("slurm/slurm_errno.h");
});

pub extern fn slurm_xcalloc(usize, usize, bool, bool, [*c]const u8, c_int, [*c]const u8) ?*anyopaque;
pub extern fn slurm_xfree([*c]?*anyopaque) void;
pub extern fn slurm_xfree_array([*c][*c]?*anyopaque) void;
pub extern fn slurm_xrecalloc([*c]?*anyopaque, usize, usize, bool, bool, [*c]const u8, c_int, [*c]const u8) ?*anyopaque;
pub extern fn slurm_xsize(item: ?*anyopaque) usize;
pub extern fn xfree_ptr(?*anyopaque) void;

pub fn versionGreaterOrEqual(major: u8, minor: u8, micro: u8) bool {
    return c.SLURM_VERSION_NUMBER >= c.SLURM_VERSION_NUM(@as(c_int, major), @as(c_int, minor), @as(c_int, micro));
}
