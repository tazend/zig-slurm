const std = @import("std");
const common = @import("../common.zig");
const CStr = common.CStr;
const xfree_ptr = @import("../SlurmAllocator.zig").slurm_xfree_ptr;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const slurm = @import("../root.zig");
const db = slurm.db;

pub fn List(comptime T: type) type {
    return opaque {
        const Self = @This();

        const DestroyFunctionSignature = ?*const fn (object: ?T) callconv(.c) void;

        pub fn noop(object: ?T) callconv(.c) void {
            _ = object;
        }

        pub extern fn slurmdb_destroy_assoc_usage(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_bf_usage(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_bf_usage_members(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_qos_usage(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_user_rec(object: ?*db.User) void;
        pub extern fn slurmdb_destroy_account_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_coord_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_clus_res_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_cluster_accounting_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_cluster_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_federation_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_accounting_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_assoc_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_event_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_instance_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_job_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_qos_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_reservation_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_step_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_res_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_txn_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_wckey_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_archive_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_tres_rec_noalloc(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_tres_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_assoc_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_user_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_cluster_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_user_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_account_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_cluster_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_federation_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_tres_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_assoc_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_event_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_instance_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_job_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_job_cond_members(job_cond: *db.Job.Filter.Flags) void;
        pub extern fn slurmdb_destroy_qos_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_reservation_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_res_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_txn_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_wckey_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_archive_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_add_assoc_cond(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_update_object(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_used_limits(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_print_tree(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_hierarchical_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_job_grouping(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_acct_grouping(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_report_cluster_grouping(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_rpc_obj(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_rollup_stats(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_stats_rec(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_slurmdb_stats(stats: *db.Step.Stats) void;

        extern fn slurm_list_append(l: ?*List(T), x: ?T) void;
        extern fn slurm_list_is_empty(l: ?*List(T)) c_int;
        extern fn slurm_list_pop(l: ?*List(T)) ?T;
        extern fn slurm_list_count(l: ?*List(T)) c_int;
        extern fn slurm_list_destroy(l: ?*List(T)) void;
        extern fn slurm_list_create(f: DestroyFunctionSignature) ?*List(T);
        extern fn slurm_list_next(i: ?*Iterator) ?T;
        extern fn slurm_list_peek_next(i: ?*Iterator) ?T;
        extern fn slurm_list_iterator_create(l: ?*List(T)) ?*Iterator;
        extern fn slurm_list_iterator_destroy(i: ?*Iterator) void;
        extern fn slurm_list_iterator_reset(i: ?*Iterator) void;

        const DestroyFunction: DestroyFunctionSignature = switch (T) {
            *db.User => slurmdb_destroy_user_rec,
            *db.Association => slurmdb_destroy_assoc_rec,
            CStr => xfree_ptr,
            else => @compileError("List destruction not implemented for: " ++ @typeName(T)),
        };

        /// The Iterator Type for a List. Whenever you need to traverse the
        /// List, you need one of them. A List can have multiple Iterators
        /// active.
        pub const Iterator = opaque {

            /// Get the next item in the List. If there is no next item, null
            /// is returned.
            pub fn next(it: *Iterator) ?T {
                return slurm_list_next(it);
            }

            // list_peek_next is not available in libslurm.so, only libslurmfull.so
            ///// Get the next item in the List, but without advancing the
            ///// Iterator. If there is no next item, null is returned.
            //pub fn peek(it: *Iterator) ?T {
            //    return slurm_list_peek_next(it);
            //}

            /// Get an Iterator for the List passed in.
            pub fn init(list: *Self) *Iterator {
                return slurm_list_iterator_create(list).?;
            }

            /// Deallocate the Iterator.
            pub fn deinit(it: *Iterator) void {
                slurm_list_iterator_destroy(it);
            }

            /// Reset the Iterator. `next` and `peek` will therefore start from
            /// the head of the List again.
            pub fn reset(it: *Iterator) void {
                slurm_list_iterator_reset(it);
            }
        };

        /// Get an `Iterator` for this List.
        pub fn iter(self: *Self) *Iterator {
            return .init(self);
        }

        /// Initialize a new List. The appropriate `DestroyFunction` for `T` is
        /// automatically detected. This works only for certain Slurm types.
        /// Use `initNoDestroyItems` or `initWithDestroyFunc` otherwise.
        pub fn init() *List(T) {
            const list = slurm_list_create(DestroyFunction);
            //const list_typed = @as(*List(T), @ptrCast(list.?));
            return list.?;
        }

        /// Initialize a new List with a custom `DestroyFunction`
        ///
        /// Note: The function you pass in must be `callconv(.c)`, as it is
        /// called from within libslurm itself.
        pub fn initWithDestroyFunc(func: DestroyFunctionSignature) *List(T) {
            const list = slurm_list_create(func);
            //const list_typed = @as(*List(T), @ptrCast(list.?));
            return list.?;
        }

        /// Initialize a new List, where its items are not automatically freed
        /// upon running `deinit`.
        pub fn initNoDestroyItems() *List(T) {
            return initWithDestroyFunc(noop);
        }

        /// Destroy this List. Usage of any methods after this function has ran
        /// will likely result in a program crash.
        /// If the List was initialised with a `DestroyFunction`, all items in
        /// this list will automatically get deallocated. This is mostly useful
        /// when you received a List from the slurmdbd.
        ///
        /// If the List was initialized with `initNoDestroyItems`, then only
        /// the List itself is deallocated, but not its items, so you can
        /// handle it yourselves, if applicable.
        pub fn deinit(self: *Self) void {
            slurm_list_destroy(self);
        }

        /// Get the size of the list
        pub fn size(self: *Self) c_int {
            return slurm_list_count(self);
        }

        /// Removes an item from the list. Can be used in a `while()` loop if
        /// you want to iterate all items while also removing them.
        pub fn pop(self: *Self) ?T {
            return slurm_list_pop(self);
        }

        /// Checks whether the List is empty.
        pub fn isEmpty(self: *Self) bool {
            return slurm_list_is_empty(self) == 1;
        }

        /// Append an item to the list.
        pub fn append(self: *Self, item: T) void {
            slurm_list_append(self, item);
        }

        /// All data will be removed from the List, and returned as an allocated slice.
        /// Caller is responsible for freeing the slice, and all individual items.
        pub fn toOwnedSlice(
            self: *Self,
            allocator: std.mem.Allocator,
        ) std.mem.Allocator.Error![]T {
            var data: []T = try allocator.alloc(T, @intCast(self.size()));

            var index: usize = 0;
            while (self.pop()) |item| {
                //const item = @as(T, @alignCast(@ptrCast(ptr)));
                data[index] = item;
                index += 1;
            }

            std.debug.assert(self.size() == 0);
            return data;
        }

        /// Returns an allocated slice of the data in this List. Caller must
        /// free the slice returned, but does not own memory of the individual
        /// items.
        pub fn toSlice(self: *Self, allocator: std.mem.Allocator) std.mem.Allocator.Error![]T {
            var data: []T = try allocator.alloc(T, @intCast(self.size()));
            var index: usize = 0;
            var list_iter = self.iter();

            while (list_iter.next()) |item| {
                data[index] = item;
                index += 1;
            }

            return data;
        }

        /// Converts the list directly into a `ArrayList(T)`. Caller is
        /// responsible to free individual items.
        pub fn toArrayList(self: *Self, allocator: std.mem.Allocator) !std.ArrayList(T) {
            return std.ArrayList(T).fromOwnedSlice(
                try self.toOwnedSlice(allocator),
            );
        }

        /// Append the slice of items to the list.
        pub fn appendSlice(self: *Self, items: []const T) void {
            for (items) |i| {
                self.append(i);
            }
        }

        /// List takes ownership of the slice. All items will be freed with the
        /// DestroyFunction with which the List was created.
        pub fn fromOwnedSlice(items: []T) *List(T) {
            var list: *List(T) = .init();
            list.appendSlice(items);
            return list;
        }

        /// Takes a slice and uses it, but when `deinit()` is called, the
        /// individual items are not freed.
        /// This works nicely if you just want to create a Slurm compatible
        /// List from an existing ArrayList.
        pub fn fromSliceUnmanaged(items: []T) *List(T) {
            var list: *List(T) = .initNoDestroyItems();
            list.appendSlice(items);
            return list;
        }
    };
}

pub fn fromCStr(items: []const [:0]const u8) *List(CStr) {
    var list: *List(CStr) = .init();
    for (items) |*i| {
        list.append(i.ptr);
    }
    return list;
}

test "core" {
    var list: *List(CStr) = .initNoDestroyItems();
    defer list.deinit();
    list.append("item 1");
    list.append("item 2");

    try std.testing.expectEqual(list.size(), 2);
    try std.testing.expect(!list.isEmpty());

    {
        const item = list.pop();
        const val = slurm.parseCStr(item).?;
        try std.testing.expectEqualStrings(val, "item 1");
        try std.testing.expectEqual(list.size(), 1);
    }

}

test "fromSliceUnmanaged" {
    const allocator = std.testing.allocator;
    var list: std.ArrayList(*db.User) = .empty;
    defer list.deinit(allocator);

    var user: db.User = .{ .name = "user1" };
    var user2: db.User = .{ .name = "user2" };
    try list.append(allocator, &user);
    try list.append(allocator, &user2);

    var slurm_list: *List(*db.User) = .fromSliceUnmanaged(list.items);
    try std.testing.expectEqual(slurm_list.size(), 2);
    // This will not free the individual items, since we created the list from
    // a slice that is externally managed.
    defer slurm_list.deinit();
}

test "fromOwnedSlice" {
    const allocator = slurm.slurm_allocator;
    var list: std.ArrayList(*db.User) = .empty;
    defer list.deinit(allocator);

    const user: *db.User = try allocator.create(db.User);
    user.* = .{ .name = try allocator.dupeZ(u8, "user1") };
    try list.append(allocator, user);

    var slurm_list: *List(*db.User) = .fromOwnedSlice(try list.toOwnedSlice(allocator));
    try std.testing.expectEqual(slurm_list.size(), 1);
    defer slurm_list.deinit();
}

test "Iterator" {
    var list: *List(*db.User) = .initNoDestroyItems();
    defer list.deinit();

    var user: db.User = .{ .name = "user1" };
    var user2: db.User = .{ .name = "user2" };
    list.append(&user);
    list.append(&user2);

    var iter = list.iter();
    defer iter.deinit();

    var index: isize = 0;
    while (iter.next()) |item| {
        const name = slurm.parseCStr(item.name).?;
        try std.testing.expectStringStartsWith(name, "user");
        index += 1;
    }

    try std.testing.expectEqual(list.size(), index);

    iter.reset();
    {
        const item = iter.next().?;
        const name = slurm.parseCStr(item.name).?;
        try std.testing.expectEqualStrings(name, "user1");
        try std.testing.expect(iter.next() != null);
    }

    //  {
    //      const item = iter.peek().?;
    //      const name = slurm.parseCStr(item.name).?;
    //      try std.testing.expectEqualStrings(name, "user2");
    //  }
}

test "toSlice, toOwnedSlice and toArrayList" {
    const allocator = std.testing.allocator;
    {
        var list: *List(CStr) = .initNoDestroyItems();
        defer list.deinit();
        list.append("item 1");

        const slice = try list.toSlice(allocator);
        defer allocator.free(slice);

        const item = std.mem.span(slice[0]);
        try std.testing.expectEqualStrings("item 1", item);
    }
    {
        var list: *List(CStr) = .initNoDestroyItems();
        defer list.deinit();
        list.append("item 1");

        const ownedSlice = try list.toOwnedSlice(allocator);
        defer allocator.free(ownedSlice);

        const item = std.mem.span(ownedSlice[0]);
        try std.testing.expectEqualStrings("item 1", item);
    }
    {
        var list: *List(CStr) = .initNoDestroyItems();
        defer list.deinit();
        list.append("item 1");

        var array_list = try list.toArrayList(allocator);
        defer array_list.deinit(allocator);

        const item = std.mem.span(array_list.items[0]);
        try std.testing.expectEqualStrings("item 1", item);
    }
}

test "appendSlice" {
    {
        var list: *List(*db.User) = .initNoDestroyItems();
        defer list.deinit();

        var user: db.User = .{ .name = "user1" };
        var user2: db.User = .{ .name = "user2" };

        list.appendSlice(&.{ &user, &user2 });
    }
    {
        var list: *List(CStr) = .initNoDestroyItems();
        defer list.deinit();

        list.appendSlice(&.{ "item1", "item2" });
    }
}

