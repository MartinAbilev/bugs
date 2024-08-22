const bs = @import("bugsshared.zig");
const bb =@import("bugsbug.zig");
const tk = @import("tokamak");

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

var Bugs :[16] bb.Bug= undefined;

// bugz httpz test
pub fn httpz() !void
{
    print("httpz init.", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var server = try tk.Server.start(gpa.allocator(), handler, .{ .port = 3001 });
    server.wait();
}
const handler = tk.chain(.{
    tk.logger(.{}),
    tk.get("/", tk.send("Hello1")),
    tk.group("/api", tk.router(api)),
    tk.send(error.NotFound),
});
const api = struct
{

    pub fn @"GET /"(allocator: std.mem.Allocator) ![]const u8 {
        return  returnState(allocator);
    }

    pub fn @"POST /"(allocator: std.mem.Allocator, data: struct {}) ![]const u8
    {
        _= data;
        return  returnState(allocator);
    }
};

var buf: [99999999]u8 = undefined;

fn returnState(allocator: std.mem.Allocator)![]const u8
{
            const JsonBugs = struct { id: usize, x: f32, y: f32, brain: bb.br.Brain };

            var x:[Bugs.len]JsonBugs = undefined;

            for(0..Bugs.len)|i|
            {
                const b = Bugs[i];
                x[i] = JsonBugs
                {
                    .id = b.id,
                    .x = b.x,
                    .y = b.y,
                    .brain = b.brain,
                };
            }

            const JSON = struct{ id: usize, bugz: [Bugs.len]JsonBugs };

            const json: JSON = .{.id=777, .bugz = x};

            var fba = std.heap.FixedBufferAllocator.init(&buf);

            var string = std.ArrayList(u8).init(fba.allocator());
            try std.json.stringify(json, .{}, string.writer());
            // try std.json.stringify(x, .{}, string.writer());

            return std.fmt.allocPrint(allocator, "{s}", .{string.items});
}

// init bugz jok
pub fn init(ctx: jok.Context) !void
{
    // _ = ctx;

    const thread = try std.Thread.spawn(.{}, httpz, .{});
    _ = thread;

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

    bb.world = try cp.World.init(ctx.allocator(), .{
        .gravity = .{ .x = 0, .y = 100 },
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
                // std.debug.print("Body A: {} \n", .{userData});
            } else {
                // std.debug.print("Body A: null userData\n", .{});
            }

            // Check if bodyB is not null and then retrieve its userData
            const bId = if (bodyB) |body| cp.c.cpBodyGetUserData(body) else null;
            if (bId) |id| {
                _= id;
                const userData = cp.c.cpBodyGetMyUserData(bodyB);

                Bugs[userData.id].fire(userData.inp);

                // std.debug.print("Body B: {p}\n", .{id});
            } else {
                // std.debug.print("Body B: null userData\n", .{});
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
    const handler1 = cp.c.cpSpaceAddCollisionHandler(bb.world.space, 1, 0);
    handler1.*.postSolveFunc = postSolve;

    const handler2 = cp.c.cpSpaceAddCollisionHandler(bb.world.space, 3, 0);
    handler2.*.preSolveFunc = preSolve;

    const handler3 = cp.c.cpSpaceAddCollisionHandler(bb.world.space, 3, 1);
    handler3.*.preSolveFunc = preSolve;

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
        const b = bb.Bug{.x=x , .y=y, .z=0};
        Bugs[i] = b;
        try Bugs[i].init(ctx, i);
    }

    // flor
    _ = try bb.world.addObject(.{
        .body = .{
            .kinematic = .{
                .position = .{ .x = 200, .y = 600 },
                .angular_velocity = 0,
            },
        },
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = -390, .y = 0 },
                    .b = .{ .x = 690, .y = 0 },
                    .radius = 10,
                    .physics = .{
                        .weight = .{ .mass = 0 },
                        .elasticity = 1.0,
                    },
                },
            },
        },
    });

    // wall right
    _ = try bb.world.addObject(.{
        .body = .{
            .kinematic = .{
                .position = .{ .x = 0, .y = 0 },
                .angular_velocity = 0,
            },
        },
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = 0, .y = 10 },
                    .b = .{ .x = 800, .y = 10 },
                    .radius = 10,
                    .physics = .{
                        .weight = .{ .mass = 0 },
                        .elasticity = 1.0,
                    },
                },
            },
        },
    });

    // wall left
    _ = try bb.world.addObject(.{
        .body = .{
            .kinematic = .{
                .position = .{ .x = 0, .y = 0 },
                .angular_velocity = 0,
            },
        },
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = 10, .y = 0 },
                    .b = .{ .x = 10, .y = 600 },
                    .radius = 10,
                    .physics = .{
                        .weight = .{ .mass = 0 },
                        .elasticity = 1.0,
                    },
                },
            },
        },
    });

    // wall right
    _ = try bb.world.addObject(.{
        .body = .{
            .kinematic = .{
                .position = .{ .x = 800, .y = 0 },
                .angular_velocity = 0,
            },
        },
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = -10, .y = 0 },
                    .b = .{ .x = -10, .y = 600 },
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
    bb.world.update(ctx.deltaSeconds());
    for(Bugs, 0..Bugs.len) |bug, i|
    {
        if(bug.y > 1000) Bugs[i].die();
        Bugs[i].update();
        // _=bug;
        // _=i;
    }

}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(null);

    j2d.begin(.{ .depth_sort = .back_to_forth });
    defer j2d.end();

    ctx.displayStats(.{});
    try bb.world.debugDraw(ctx.renderer());

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
    bb.world.deinit();

    for(0..svg.len)|i|
    {
        svg[i].destroy();
        tex[i].destroy();
    }
}

