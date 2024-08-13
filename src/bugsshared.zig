const std = @import("std");
const jok = @import("jok");

const cp = jok.cp;

pub fn constrain (world: cp.World, a: ?*cp.c.cpBody, b: ?*cp.c.cpBody) void
{
    const pj = cp.c.cpPinJointNew(a, b, .{.x=0, .y=0}, .{.x=0, .y=0 });
    _= cp.c.cpSpaceAddConstraint(world.space, pj);
}
