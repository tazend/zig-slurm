const std = @import("std");
const common = @import("common.zig");
const parseCStr = common.parseCStr;
const slurm_allocator = @import("root.zig").slurm_allocator;
const tres = @import("tres.zig");

pub const GPU = struct {
    type: ?[]const u8 = null,
    count: u64 = 1,

    pub const Iterator = struct {
        iter: std.mem.SplitIterator(u8, .scalar),

        pub fn init(str: [:0]const u8, delim: u8) GPU.Iterator {
            return .{
                .iter = std.mem.splitScalar(u8, str, delim),
            };
        }

        pub fn next(self: *GPU.Iterator) ?GPU {
            while (self.iter.next()) |item| {
                const tres_pair = tres.Pair.fromItem(item, '=');
                if (!std.mem.eql(u8, tres_pair.type, "gres")) continue;

                if (tres_pair.name) |name| {
                    if (!std.mem.startsWith(u8, name, "gpu")) continue;
                } else break;

                return GPU.fromTresPair(tres_pair);
            }

            return null;
        }
    };

    pub fn iter(str: [:0]const u8, delim: u8) GPU.Iterator {
        return GPU.Iterator.init(str, delim);
    }

    pub fn fromTresPair(tres_pair: tres.Pair) GPU {
        var gpu: GPU = .{
            .count = tres_pair.count,
        };

        var splitted = std.mem.splitScalar(u8, tres_pair.name.?, ':');
        _ = splitted.first();
        if (splitted.next()) |real_typ| {
            gpu.type = real_typ;
        }

        return gpu;
    }
};

pub const Gres = struct {
    name: []const u8,
    type: ?[]const u8 = null,
    name_and_type: []const u8,
    count: u64 = 1,

    pub const Iterator = struct {
        iter: std.mem.SplitIterator(u8, .scalar),

        pub fn init(str: [:0]const u8, delim: u8) Gres.Iterator {
            return .{
                .iter = std.mem.splitScalar(u8, str, delim),
            };
        }

        pub fn next(self: *Gres.Iterator) ?Gres {
            while (self.iter.next()) |item| {
                const tres_pair = tres.Pair.fromItem(item, '=');
                if (!std.mem.eql(u8, tres_pair.type, "gres")) continue;
                if (tres_pair.name == null) continue;

                return Gres.fromTresPair(tres_pair);
            }

            return null;
        }
    };

    pub fn iter(str: [:0]const u8, delim: u8) Gres.Iterator {
        return Gres.Iterator.init(str, delim);
    }

    pub fn fromTresPair(tres_pair: tres.Pair) Gres {
        var gres: Gres = .{
            .name = tres_pair.name.?,
            .count = tres_pair.count,
            .name_and_type = tres_pair.name_and_type[std.mem.indexOfScalar(u8, tres_pair.name_and_type, '/').? + 1 ..],
        };

        var splitted = std.mem.splitScalar(u8, gres.name, ':');
        _ = splitted.first();
        if (splitted.next()) |real_typ| {
            gres.type = real_typ;
        }

        return gres;
    }
};
