const std = @import("std");
const common = @import("common.zig");
const parseCStr = common.parseCStr;
const slurm_allocator = @import("root.zig").slurm_allocator;

pub const MemoryUnit = enum(u64) {
    K = std.math.pow(u64, 2, 10),
    M = std.math.pow(u64, 2, 20),
    G = std.math.pow(u64, 2, 30),
    T = std.math.pow(u64, 2, 40),
    P = std.math.pow(u64, 2, 50),
    E = std.math.pow(u64, 2, 60),

    pub const possibles = [_][]const u8{ "K", "M", "G", "T", "P", "E", "Z" };
};

pub const DehumanizeOptions = struct {
    target: MemoryUnit = .M,
    decimals: u8 = 0,
};

pub const DehumanizeError = error{InvalidUnit} || std.fmt.ParseIntError;

pub fn dehumanize(str: []const u8, options: DehumanizeOptions) DehumanizeError!u64 {
    var maybe_unit: ?[]const u8 = null;
    for (MemoryUnit.possibles) |u| {
        const maybe = std.mem.containsAtLeast(u8, str, 1, u);
        if (!maybe) continue else maybe_unit = u;
        break;
    }

    const unit = maybe_unit orelse return try std.fmt.parseInt(u64, str, 10);
    const unit_value = @intFromEnum(std.meta.stringToEnum(MemoryUnit, unit).?);

    var splitted = std.mem.splitAny(u8, str, unit);
    const value = try std.fmt.parseInt(
        u64,
        std.mem.trim(u8, splitted.first(), " "),
        10,
    );

    const bytes: u64 = value * unit_value;
    const target_size = bytes / @intFromEnum(options.target);

    return target_size;
}

pub const Pair = struct {
    type: []const u8,
    name: ?[]const u8 = null,
    name_and_type: []const u8,
    count: u64 = 1,

    pub const Iterator = struct {
        iter: std.mem.SplitIterator(u8, .scalar),

        pub fn init(str: [:0]const u8, delim: u8) Pair.Iterator {
            return .{
                .iter = std.mem.splitScalar(u8, str, delim),
            };
        }

        pub fn next(self: *Pair.Iterator) ?Pair {
            const item = self.iter.next() orelse return null;
            return Pair.fromItem(item, '=');
        }
    };

    pub fn fromItem(kv: []const u8, delim: u8) Pair {
        var it = std.mem.splitScalar(u8, kv, delim);
        const name_and_type = it.first();

        var it2 = std.mem.splitScalar(u8, name_and_type, '/');
        const typ = it2.first();
        const name: ?[]const u8 = it2.next() orelse null;

        const count = blk: {
            if (std.mem.eql(u8, typ, "mem")) {
                break :blk dehumanize(it.rest(), .{}) catch 0;
            } else {
                break :blk std.fmt.parseInt(u64, it.rest(), 10) catch 1;
            }
        };

        return .{
            .type = typ,
            .name = name,
            .name_and_type = name_and_type,
            .count = count,
        };
    }
};

pub fn iter(str: [:0]const u8, delim: u8) Pair.Iterator {
    return Pair.Iterator.init(str, delim);
}

test "parse_tres" {
    const s = "cpu=56,mem=470G,billing=56,gres/gpu=3,gres/gpu:nvidia-a100=5";
    var items = iter(s, ',');
    const cpu = items.next().?;
    try std.testing.expectEqualSlices(u8, "cpu", cpu.type);
    try std.testing.expectEqual(56, cpu.count);

    const mem = items.next().?;
    try std.testing.expectEqualSlices(u8, "mem", mem.type);
    try std.testing.expectEqual(470 * 1024, mem.count);

    const billing = items.next().?;
    try std.testing.expectEqualSlices(u8, "billing", billing.type);
    try std.testing.expectEqual(56, billing.count);

    const gres_gpu = items.next().?;
    try std.testing.expectEqualSlices(u8, "gres", gres_gpu.type);
    try std.testing.expectEqualSlices(u8, "gpu", gres_gpu.name.?);
    try std.testing.expectEqual(3, gres_gpu.count);

    const gres_gpu_nvidia = items.next().?;
    try std.testing.expectEqualSlices(u8, "gres", gres_gpu_nvidia.type);
    try std.testing.expectEqualSlices(u8, "gpu:nvidia-a100", gres_gpu_nvidia.name.?);
    try std.testing.expectEqual(5, gres_gpu_nvidia.count);
}

test "dehumanize" {
    const g = try dehumanize("470G", .{});
    try std.testing.expectEqual(g, 470 * 1024);

    const t = try dehumanize("512T", .{});
    try std.testing.expectEqual(t, 512 * 1024 * 1024);

    const with_target = try dehumanize("512T", .{ .target = .T });
    try std.testing.expectEqual(with_target, 512);
}
