const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
pub extern fn slurm_xcalloc(usize, usize, bool, bool, [*c]const u8, c_int, [*c]const u8) ?*anyopaque;
pub extern fn slurm_xfree([*c]?*anyopaque) void;
pub extern fn slurm_xfree_array([*c][*c]?*anyopaque) void;
pub extern fn slurm_xrecalloc([*c]?*anyopaque, usize, usize, bool, bool, [*c]const u8, c_int, [*c]const u8) ?*anyopaque;
pub extern fn slurm_xsize(item: ?*anyopaque) usize;
pub extern fn slurm_xfree_ptr(?*anyopaque) void;

pub fn alloc(
    context: *anyopaque,
    len: usize,
    alignment: std.mem.Alignment,
    return_address: usize,
) ?[*]u8 {
    _ = context;
    _ = return_address;
    assert(len > 0);
    // assert(alignment <= comptime std.math.log2_int(usize, @alignOf(std.c.max_align_t)));
    assert(alignment.compare(.lte, comptime .fromByteUnits(@alignOf(std.c.max_align_t))));
    const src: std.builtin.SourceLocation = @src();
    return @as(
        ?[*]u8,
        @ptrCast(
            slurm_xcalloc(
                1,
                len,
                true,
                false,
                src.file,
                src.line,
                src.fn_name,
            ),
        ),
    );
}

pub fn resize(
    context: *anyopaque,
    buf: []u8,
    alignment: std.mem.Alignment,
    new_len: usize,
    return_address: usize,
) bool {
    _ = context;
    _ = alignment;
    _ = return_address;
    return new_len <= buf.len;
}

pub fn remap(
    context: *anyopaque,
    buf: []u8,
    alignment: std.mem.Alignment,
    new_len: usize,
    return_address: usize,
) ?[*]u8 {
    _ = context;
    _ = alignment;
    _ = return_address;
    const src: std.builtin.SourceLocation = @src();
    return @as(
        ?[*]u8,
        @ptrCast(
            slurm_xrecalloc(
                @constCast(@alignCast(@ptrCast(&buf.ptr))),
                1,
                new_len,
                true,
                false,
                src.file,
                src.line,
                src.fn_name,
            ),
        ),
    );
}

pub fn free(
    context: *anyopaque,
    buf: []u8,
    alignment: std.mem.Alignment,
    return_address: usize,
) void {
    _ = context;
    _ = alignment;
    _ = return_address;
    slurm_xfree(@constCast(@alignCast(@ptrCast(&buf.ptr))));
}

pub const slurm_allocator = Allocator{
    .ptr = undefined,
    .vtable = &slurm_allocator_vtable,
};
const slurm_allocator_vtable = Allocator.VTable{
    .alloc = alloc,
    .resize = resize,
    .free = free,
    .remap = remap,
};
