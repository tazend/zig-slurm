const std = @import("std");
const common = @import("../common.zig");
const CStr = common.CStr;
const xfree_ptr = @import("../SlurmAllocator.zig").slurm_xfree_ptr;
const NoValue = common.NoValue;
const Infinite = common.Infinite;
const db = @import("../db.zig");

pub fn List(comptime T: type) type {
    return opaque {
        const Self = @This();

        const DestroyFunctionSignature = ?*const fn (object: ?*anyopaque) callconv(.C) void;

        pub extern fn slurmdb_destroy_assoc_usage(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_bf_usage(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_bf_usage_members(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_qos_usage(object: ?*anyopaque) void;
        pub extern fn slurmdb_destroy_user_rec(object: ?*anyopaque) void;
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

        const DestroyFunction: DestroyFunctionSignature = switch (T) {
            *db.User => slurmdb_destroy_user_rec,
            *db.Association => slurmdb_destroy_assoc_rec,
            CStr => xfree_ptr,
            else => @compileError("List destruction not implemented for: " ++ @typeName(T)),
        };

        pub const Iterator = struct {
            const list_itr_t = opaque {};
            c_handle: *list_itr_t,
            index: usize = 0,

            pub extern fn slurm_list_next(i: ?*list_itr_t) ?T;
            pub fn next(it: *Iterator) ?T {
                defer it.index += 1;
                const item = slurm_list_next(it.c_handle);
                return item;
            }

            extern fn slurm_list_iterator_create(l: ?*List(T)) ?*list_itr_t;
            pub fn init(list: *Self) Iterator {
                const handle = slurm_list_iterator_create(list);
                return Iterator{
                    .c_handle = handle.?,
                };
            }

            extern fn slurm_list_iterator_destroy(i: ?*list_itr_t) void;
            pub fn deinit(it: *Iterator) void {
                slurm_list_iterator_destroy(it.c_handle);
                it.c_handle = undefined;
            }

            extern fn slurm_list_iterator_reset(i: ?*list_itr_t) void;
            pub fn reset(it: *Iterator) void {
                slurm_list_iterator_reset(it.c_handle);
                it.index = 0;
            }
        };

        extern fn slurm_list_create(f: DestroyFunctionSignature) ?*List(T);
        pub fn init() *List(T) {
            const list = slurm_list_create(DestroyFunction);
            const list_typed = @as(*List(T), @ptrCast(list.?));
            return list_typed;
        }

        pub fn initWithDestroyFunc(func: DestroyFunctionSignature) *List(T) {
            const list = slurm_list_create(func);
            const list_typed = @as(*List(T), @ptrCast(list.?));
            return list_typed;
        }

        extern fn slurm_list_destroy(l: ?*List(T)) void;
        pub fn deinit(self: *Self) void {
            slurm_list_destroy(self);
        }

        extern fn slurm_list_count(l: ?*List(T)) c_int;
        pub fn size(self: *Self) c_int {
            return slurm_list_count(self);
        }

        pub fn iter(self: *Self) Iterator {
            return Iterator.init(self);
        }

        extern fn slurm_list_pop(l: ?*List(T)) ?T;
        pub fn pop(self: *Self) ?T {
            return slurm_list_pop(self);
        }

        extern fn slurm_list_is_empty(l: ?*List(T)) c_int;
        pub fn isEmpty(self: *Self) bool {
            return slurm_list_is_empty(self) == 1;
        }

        pub extern fn slurm_list_append(l: ?*List(T), x: ?T) void;
        pub fn append(self: *Self, item: T) void {
            slurm_list_append(self, item);
        }

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
            self.deinit();
            return data;
        }

        pub fn constSlice(self: *Self, allocator: std.mem.Allocator) std.mem.Allocator.Error![]const T {
            var data: []T = try allocator.alloc(T, @intCast(self.size()));
            var index: usize = 0;
            var list_iter = self.iter();

            while (list_iter.next()) |item| {
                data[index] = item;
                index += 1;
            }

            return data;
        }

        pub fn toArrayList(self: *Self, allocator: std.mem.Allocator) !std.ArrayList(T) {
            return std.ArrayList(T).fromOwnedSlice(
                allocator,
                try self.toOwnedSlice(allocator),
            );
        }

        pub fn fromOwnedSlice(items: []T) *List(T) {
            var list = List(T).init();
            for (items) |*i| {
                list.append(@ptrCast(i));
            }
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

test "List" {}
