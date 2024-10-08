pub const std = @import("std");
pub const jok = @import("jok");

pub const cp = jok.cp;
pub const font = jok.font;
pub const j2d = jok.j2d;
pub const sdl = jok.sdl;


pub const print = std.debug.print;

// parents two cpBodies together
pub fn constrain (wld: cp.World, a: ?*cp.c.cpBody, b: ?*cp.c.cpBody) void
{
    const pj = cp.c.cpPinJointNew(a, b, .{.x=0, .y=0}, .{.x=0, .y=0 });
    const rj = cp.c.cpPinJointNew(a, b, .{.x=10, .y=0}, .{.x=0, .y=0 });
    _= cp.c.cpSpaceAddConstraint(wld.space, pj);
    _= cp.c.cpSpaceAddConstraint(wld.space, rj);
}

