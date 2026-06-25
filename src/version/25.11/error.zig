const std = @import("std");
const gen = @import("error/gen.zig");
const entries = gen.entries;
pub const Error = gen.Error;

const SLURM_SUCCESS: c_int = 0;

pub const ErrorEntry = struct {
    code: c_int,
    name: [:0]const u8,
    description: [:0]const u8,
};

pub fn toEntry(errt: Error) ErrorEntry {
    inline for (entries) |entry| {
        if (entry[0] == errt) {
            return .{
                .code = entry[1],
                .name = @errorName(entry[0]),
                .description = entry[2],
            };
        }
    }
    unreachable;
}

pub fn checkRpc(rc: c_int) Error!void {
    if (rc == SLURM_SUCCESS) return;

    // Sometimes, Slurm functions only return -1 to indicate failure and set
    // errno
    const errno = if (rc == -1)
        std.c._errno().*
    else
        rc;

    // This should find an entry, since they are getting auto-generated from the
    // source.
    inline for (entries) |entry| {
        if (entry[1] == errno) return entry[0];
    }

    // Just to be safe, return error.Generic if we didn't find anything
    return error.Generic;
}

pub fn getError() Error!void {
    return checkRpc(std.c._errno().*);
}

test "checkRpc" {
    try std.testing.expectError(error.Generic, checkRpc(5));
    try std.testing.expectError(error.Generic, checkRpc(-1));
    try std.testing.expectError(error.DataParserInvalidState, checkRpc(9215));
}

test "toEntry" {
    const entry = toEntry(error.DataParsingDepth);
    try std.testing.expectEqual(entry.code, 9214);
    try std.testing.expectEqualStrings(entry.name, @errorName(error.DataParsingDepth));
    try std.testing.expectEqualStrings(entry.description, "Parsing tree too deep. Possible cyclic parsing detected");
}
