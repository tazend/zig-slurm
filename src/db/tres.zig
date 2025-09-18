const common = @import("../common.zig");
const db = @import("../db.zig");
const CStr = common.CStr;
const List = db.List;
const Connection = db.Connection;

pub const TrackableResource = extern struct {
    alloc_secs: u64 = 0,
    rec_count: u32 = 0,
    count: u64 = 0,
    id: u32 = 0,
    name: ?CStr = null,
    type: ?CStr = null,

    pub const Filter = extern struct {
        count: u64 = 0,
        format_list: ?*List(CStr) = null,
        id_list: ?*List(CStr) = null,
        name_list: ?*List(CStr) = null,
        type_list: ?*List(CStr) = null,
        with_deleted: u16 = 0,
    };
};

pub extern fn slurmdb_tres_get(
    db_conn: ?*Connection,
    tres_cond: *TrackableResource.Filter,
) ?*List(*TrackableResource);

pub fn load(conn: *Connection, filter: TrackableResource.Filter) !*List(*TrackableResource) {
    const data = slurmdb_tres_get(conn, @constCast(&filter));
    if (data) |d| {
        return d;
    } else {
        // TODO: Better error, this is just temporary.
        return error.Generic;
    }
}
