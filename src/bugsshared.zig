const std = @import("std");
pub const jok = @import("jok");

pub const cp = jok.cp;

pub const print = std.debug.print;

pub fn constrain (world: cp.World, a: ?*cp.c.cpBody, b: ?*cp.c.cpBody) void
{
    const pj = cp.c.cpPinJointNew(a, b, .{.x=0, .y=0}, .{.x=0, .y=0 });
    _= cp.c.cpSpaceAddConstraint(world.space, pj);
}
