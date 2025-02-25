const c = @import("c.zig").c;
const std = @import("std");
const SlurmError = @import("error.zig").Error;

pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();
        handle: *c.list_t,
        size: usize = 0,

        pub const Iterator = struct {
            list: *Self,
            c_handle: *c.list_itr_t,
            index: usize = 0,

            pub fn next(it: *Iterator) ?*T {
                defer it.index += 1;
                if (it.index >= it.list.size) return null;
                const item = @as(*T, @alignCast(@ptrCast(c.slurm_list_next(
                    it.c_handle,
                ))));
                return item;
            }

            pub fn reset(it: *Iterator) void {
                c.slurm_list_iterator_destroy(it.c_handle);
                it.index = 0;
            }

            pub fn from_list(list: *Self) Iterator {
                const handle = c.slurm_list_iterator_create(list.handle);
                return Iterator{
                    .list = list,
                    .c_handle = handle.?,
                };
            }
        };

        pub fn iter(self: *Self) Iterator {
            return Iterator.from_list(self);
        }

        pub fn from_c(c_list: *c.list_t) Self {
            return .{
                .handle = c_list,
                .size = @intCast(c.slurm_list_count(c_list)),
            };
        }

        pub fn toOwnedSlice(
            self: *Self,
            allocator: std.mem.Allocator,
        ) std.mem.Allocator.Error![]*T {
            var data: []*T = try allocator.alloc(*T, @intCast(self.size));

            var it = self.iter();
            while (it.next()) |ptr| {
                const item = @as(*T, @alignCast(@ptrCast(ptr)));
                std.debug.print("idx is {d}\n", .{it.index});
                std.debug.print("size is {d}\n", .{self.size});
                data[it.index - 1] = item;
            }

            // TODO: Convenience function to free a slice of T
            self.size = 0;

            return data;
        }
    };
}
