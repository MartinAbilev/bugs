const bs = @import("bugsshared.zig");
const std = bs.std;
const jok = bs.jok;

const cp = bs.cp;
const font = jok.font;
const j2d = jok.j2d;
const sdl = jok.sdl;

const print = bs.print;

var rng: std.Random.Xoshiro256 = undefined;

var svg: [2]jok.svg.SvgBitmap = undefined;
var tex: [2]sdl.Texture = undefined;

var Bugs :[3] bs.Bug= undefined;

pub fn init(ctx: jok.Context) !void
{
    // _ = ctx;
    std.log.info("game init", .{});

     rng = std.Random.DefaultPrng.init(
        @intCast(std.time.timestamp()),
    );


    svg[0] = try jok.svg.createBitmapFromFile(
        ctx.allocator(),
        "assets/bug.svg",
        .{},
    );
    svg[1] = try jok.svg.createBitmapFromFile(
        ctx.allocator(),
        "assets/inp.svg",
        .{},
    );

    bs.world = try cp.World.init(ctx.allocator(), .{
        .gravity = .{ .x = 0, .y = 600 },
    });

    const postSolve = struct {
        fn postSolve(arb: ?*cp.c.cpArbiter, space: ?*cp.c.cpSpace, data: ?*anyopaque) callconv(.C) void
        {

        if (arb) |arbiter|
        {
            // _= arbiter;
            var bodyA: ?*cp.c.cpBody = null;
            var bodyB: ?*cp.c.cpBody = null;

            cp.c.cpArbiterGetBodies(arbiter, &bodyA, &bodyB);

            // Check if bodyA is not null and then retrieve its userData

            if (bodyA) |body| {
                const userData = cp.c.cpBodyGetMyUserData(body);
                 // make bug dead;
                Bugs[userData.id].die();
                // std.debug.print("Body A: {} \n", .{userData});
            } else {
                std.debug.print("Body A: null userData\n", .{});
            }

            // Check if bodyB is not null and then retrieve its userData
            const bId = if (bodyB) |body| cp.c.cpBodyGetUserData(body) else null;
            if (bId) |id| {
                _= id;
                // std.debug.print("Body B: {p}\n", .{id});
            } else {
                std.debug.print("Body B: null userData\n", .{});
            }

        } else {
            std.debug.print("Arbiter is null.\n", .{});
        }
        // _=arb;
        _= space;
        _= data;

        }
    }.postSolve;

    const preSolve = struct {
        fn preSolve(arb: ?*cp.c.cpArbiter, space: ?*cp.c.cpSpace, data: ?*anyopaque) callconv(.C) u8
        {

        if (arb) |arbiter|
        {
            // _= arbiter;
            var bodyA: ?*cp.c.cpBody = null;
            var bodyB: ?*cp.c.cpBody = null;

            cp.c.cpArbiterGetBodies(arbiter, &bodyA, &bodyB);

            // Check if bodyA is not null and then retrieve its userData
            const aId = if (bodyA) |body| cp.c.cpBodyGetUserData(body) else null;
            if (aId) |id| {
                _=id;
                 const userData = cp.c.cpBodyGetMyUserData(bodyA);
                 // make given nuron to fire;
                 Bugs[userData.id].fire(userData.inp);
                std.debug.print("Body A: {} \n", .{userData});
            } else {
                std.debug.print("Body A: null userData\n", .{});
            }

            // Check if bodyB is not null and then retrieve its userData
            const bId = if (bodyB) |body| cp.c.cpBodyGetUserData(body) else null;
            if (bId) |id| {
                std.debug.print("Body B: {p}\n", .{id});
            } else {
                std.debug.print("Body B: null userData\n", .{});
            }

        } else {
            std.debug.print("Arbiter is null.\n", .{});
        }
        // _=arb;
        _= space;
        _= data;
        return 1;
        }
    }.preSolve;


    // Create a collision handler
    const handler = cp.c.cpSpaceAddCollisionHandler(bs.world.space, 1, 0);
    handler.*.postSolveFunc = postSolve;

    const handler2 = cp.c.cpSpaceAddCollisionHandler(bs.world.space, 0, 0);
    handler2.*.preSolveFunc = preSolve;

    for(svg, 0..)|asvg, i|
    tex[i] = try jok.utils.gfx.createTextureFromPixels(
        ctx,
        asvg.pixels,
        asvg.format,
        .static,
        asvg.width,
        asvg.height,
    );

    const size = ctx.getCanvasSize();

    for(0..Bugs.len)|i|
    {
        const ii: f32 = @floatFromInt(i);
        const x: f32 = 100 * ii + size.x / 2;
        const y: f32 = 100 * ii + size.y / 4;
        const b = bs.Bug{.x=x , .y=y, .z=0};
        Bugs[i] = b;
        try Bugs[i].init(ctx, i);
    }

    _ = try bs.world.addObject(.{
        .body = .{
            .kinematic = .{
                .position = .{ .x = 200, .y = 600 },
                .angular_velocity = 0,
            },
        },
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = -100, .y = 0 },
                    .b = .{ .x = 500, .y = 0 },
                    .radius = 10,
                    .physics = .{
                        .weight = .{ .mass = 0 },
                        .elasticity = 1.0,
                    },
                },
            },
        },
    });
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    // _ = ctx;
    bs.world.update(ctx.deltaSeconds());
    for(Bugs, 0..Bugs.len) |bug, i|
    {
        Bugs[i].update();
        _=bug;
        // _=i;
    }

}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(null);

    // const size = ctx.getCanvasSize();
    // const rect_color = sdl.Color.rgba(0, 128, 0, 120);
    // var area: sdl.RectangleF = undefined;
    // var atlas: *font.Atlas = undefined;

    j2d.begin(.{ .depth_sort = .back_to_forth });
    defer j2d.end();

    ctx.displayStats(.{});
    try bs.world.debugDraw(ctx.renderer());

    for(Bugs)|bug|
    {
        const bugx: f32 =  bug.x;
        const bugy: f32 =  bug.y;
        try j2d.image(
            tex[0],
            .{
                .x = bugx,
                .y = bugy,
            },
            .{
                .rotate_degree = ctx.seconds() * 60 + bug.x,
                .scale =.{.x = 0.1, .y = 0.1},
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
            },
        );
        for(bug.brain.inputs.nurons, 0..)|inp, i|
        {
            _=i;
            try j2d.image(
            tex[1],
            .{
                .x = inp.x,
                .y = inp.y,
            },
            .{
                .rotate_degree = ctx.seconds() * 60 + bug.x,
                .scale =.{.x = 0.05, .y = 0.05},
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
            },
            );
        }

    }
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});
    bs.world.deinit();

    for(0..svg.len)|i|
    {
        svg[i].destroy();
        tex[i].destroy();
    }
}

