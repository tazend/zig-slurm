const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const slurm_xcalloc = @import("c.zig").slurm_xcalloc;
const slurm_xfree = @import("c.zig").slurm_xfree;

pub fn alloc(
    _: *anyopaque,
    len: usize,
    log2_ptr_align: u8,
    return_address: usize,
) ?[*]u8 {
    _ = return_address;
    assert(len > 0);
    assert(log2_ptr_align <= comptime std.math.log2_int(usize, @alignOf(std.c.max_align_t)));
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
    _: *anyopaque,
    buf: []u8,
    log2_buf_align: u8,
    new_len: usize,
    return_address: usize,
) bool {
    _ = log2_buf_align;
    _ = return_address;
    return new_len <= buf.len;
}

pub fn free(
    _: *anyopaque,
    buf: []u8,
    log2_buf_align: u8,
    return_address: usize,
) void {
    _ = log2_buf_align;
    _ = return_address;
    slurm_xfree(@constCast(@alignCast(@ptrCast(&buf.ptr))));
}
