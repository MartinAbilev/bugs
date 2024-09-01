const bs = @import("bugsshared.zig");
const bb =@import("bugsbug.zig");
const nn = @import("bugsnuron.zig");

pub const br = @import("bugsbrain.zig");
const conf = @import("bugsconfig.zig");


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

var Bugs :[conf.maxBugs] bb.Bug= undefined;

var championBrain: br.Brain = undefined;

var isDebugVisible = false;

var bestTime: i64 = 0;
var bestestTime: i64 = 0;
const hiveSize: usize = conf.maxBugs;
var deaths: usize = 0;

var GOD: ?*cp.c.cpBody = undefined;

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


pub const Inputs = struct {nurons:[conf.maxIn] nn.Nuron};
pub const Outputs = struct {nurons:[conf.maxOut] nn.Nuron};
pub const Hidden = struct {nurons:[conf.maxHidden] nn.Nuron};
const brainSize = conf.maxIn + conf.maxHidden + conf.maxOut;
    const BBrain:type = struct
    {
        inputs: Inputs,
        hidden: Hidden,
        outputs: Outputs,
        size: usize = brainSize,
        color: sdl.Color = .{ .r = 255, .g =255, .b = 255 },
    };
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

    pub fn @"PUT /upload"(allocator: std.mem.Allocator, data: bb.br.Brain ) ![]const u8
    {
        print("Upload Done {}\n", .{data});

        for(0..Bugs.len)|i|
        {
            Bugs[i].brain = data;
        }
        const json = .{.status=400};

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};

        var string = std.ArrayList(u8).init(gpa.allocator());
        try std.json.stringify(json, .{}, string.writer());
        bestTime = 0;
        deaths = 0;
        return   std.fmt.allocPrint(allocator, "{s}", .{string.items});
    }
};

fn returnState(allocator: std.mem.Allocator)![]const u8
{
    const bugzToSend: usize = 3;
    const JsonBugs = struct { id: usize, x: f32, y: f32, brain: bb.br.Brain };
    var x:[bugzToSend]JsonBugs = undefined;

    for(0..bugzToSend)|i|
    {
        const b = Bugs[i];
        const brain = b.brain;

        x[i] = JsonBugs
        {
            .id = b.id,
            .x = b.x,
            .y = b.y,
            .brain = brain,
        };
    }

    const JSON = struct{ id: usize, bugz: [bugzToSend]JsonBugs };

    const json: JSON = .{.id=777, .bugz = x};

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var string = std.ArrayList(u8).init(gpa.allocator());
    try std.json.stringify(json, .{}, string.writer());

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
        .gravity = .{ .x = 0, .y = 10 },
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
                 const chb: *br.Brain = &championBrain;
                 hiveDeath();
                Bugs[userData.id].die(chb);
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
                // const userData = cp.c.cpBodyGetMyUserData(bodyB);

                // Bugs[userData.id].fire(userData.inp);

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

    // GOD
    const GODiD = try bb.world.addObject(.{
        .body = .{
            .kinematic = .{
                .position = .{ .x = 400, .y = 300 },
                .angular_velocity = 0,
            },
        },
        .shapes = &[_]cp.World.ObjectOption.ShapeProperty{
            .{
                .segment = .{
                    .a = .{ .x = -10, .y = 0 },
                    .b = .{ .x = 10, .y = 0 },
                    .radius = 20,
                    .physics = .{
                        .weight = .{ .mass = 0 },
                        .elasticity = 1.0,
                    },
                },
            },
        },
    });
    GOD = bb.world.objects.items[GODiD].body.?;
    cp.c.cpShapeSetCollisionType(bb.world.objects.items[GODiD].shapes[0], 1);

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

pub fn event(ctx: jok.Context, e: sdl.Event) !void
{
    switch (e)
    {
        .mouse_motion => |me|
        {
            const mouse_state = ctx.getMouseState();
            if (!mouse_state.buttons.getPressed(.left))
            {
                return;
            }

            // camera.rotateAroundBy(
            //     null,
            //     @as(f32, @floatFromInt(me.delta_x)) * 0.01,
            //     @as(f32, @floatFromInt(me.delta_y)) * 0.01,
            // );

            const dx: f32 = @floatFromInt(me.delta_x);
            const dy: f32 = @floatFromInt(me.delta_y);

            const posCurrent = cp.c.cpBodyGetPosition(GOD);
            const mpos = cp.c.cpv(posCurrent.x + dx, posCurrent.y + dy);
            cp.c.cpBodySetPosition(GOD, mpos);
        },
        .mouse_wheel => |me|
        {
            _=me;
            // camera.zoomBy(@as(f32, @floatFromInt(me.delta_y)) * -0.1);
            isDebugVisible = !isDebugVisible;
        },
        else => {},
    }
}

pub fn hiveDeath() void
{
    deaths +=1;
    if(deaths>=hiveSize)
    {
        deaths = 0;
        if(bestTime > bestestTime)bestestTime = bestTime;
        // bestTime -=hiveSize;
        bestTime -= hiveSize;
    }
    // print("hive size: {}, deaths: {}, bestTime: {}, bestestTime {} \n", .{hiveSize, deaths, bestTime, bestestTime});
}
pub fn update(ctx: jok.Context) !void {
    // _ = ctx;
    bb.world.update(ctx.deltaSeconds());
    for(Bugs, 0..Bugs.len) |bug, i|
    {
        const chb: *br.Brain = &championBrain;
        if(bug.y > 1000) Bugs[i].die(chb);
        const bt: *i64 = &bestTime;
        Bugs[i].update(bt, chb);
        // _=bug;
        // _=i;
    }

}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(null);

    j2d.begin(.{ .depth_sort = .back_to_forth });

    if(isDebugVisible)
    {
        ctx.displayStats(.{});
        try bb.world.debugDraw(ctx.renderer());
    }

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
            var center:sdl.PointF = if(i<4)
            .{.x=inp.x, .y=inp.y}
            else
            .{.x=bug.x, .y=bug.y};

            if(i == 4) center = .{.x=bug.x - 10.0, .y=bug.y};
            if(i == 5) center = .{.x=bug.x + 10.0, .y=bug.y};
            if(i == 6) center = .{.x=bug.x - 10.0, .y=bug.y};
            if(i == 7) center = .{.x=bug.x + 10.0, .y=bug.y};

            if(i == 8) center = .{.x=bug.x , .y= bug.y - 10};
            if(i == 9) center = .{.x=bug.x , .y= bug.y - 10};

            const radius: f32 = 3.0;
            const outvalue: f32 = if(i<bug.brain.outputs.nurons.len)bug.brain.outputs.nurons[i].neuronvalue else 0.0;
            // const outhresold: f32 =  if(i<bug.brain.outputs.nurons.len)bug.brain.outputs.nurons[i].thresold else 0.0;
            const inpvalue = bug.brain.inputs.nurons[i].neuronvalue;
            // const inpthresold = bug.brain.inputs.nurons[i].thresold;
            var cr: u8= 100;
            var cg: u8= 100;


            if(outvalue>0)
            cr = 255
            else cr = 100;

            if(inpvalue>0)
            cg = 255
            else cg = 0;

            const color: sdl.Color = .{.r=cr, .g=cg, .b=0};
            const opt: j2d.CircleOption = .{
                                            .thickness = 3.0,
                                            .num_segments = 8,
                                            .depth = 0.5,
                                        };
            try j2d.circle(
                center,
                radius,
                color,
                opt,
            );
        }


        var x: f32 = 0;
        var y: f32 = 0;
        const nlen: f32 = @floatFromInt(bug.brain.hidden.nurons.len);
        const square: f32 = std.math.sqrt(nlen);
        const dim: f32 = 40;
        const radius1: f32 = (dim / square)/2;
        const w: f32 = square;
        // const h: f32 = w;
        const xspacing: f32 = (radius1*2);
        const yspacing: f32 = (radius1*2);

        for(bug.brain.hidden.nurons, 0..bug.brain.hidden.nurons.len)|hid, iu|
        {
            _= iu;

            const center:sdl.PointF =
            .{
                .x=bug.x + xspacing/2 + (x * xspacing) - (w * xspacing)/2 ,
                .y=bug.y + yspacing/2 + (y * yspacing) - (w * yspacing)/2
             };

            const c =  hid.neuronvalue;
            var cb: u8 = 0;
            if(c>0.5)cb=255;
            const fcb: f32 = @floatFromInt(cb);
            const cr: u8 = @intFromFloat(fcb / 2);
            const color: sdl.Color = .{.r = cr, .g= 0, .b = cb};
            const opt: j2d.CircleOption = .{
                                            .thickness = 1.0,
                                            .num_segments =3,
                                            .depth = 0.5,
                                        };
            try j2d.circle(
                center,
                radius1,
                color,
                opt,
            );

            x += 1;
            if(x>=w)
            {
                x = 0;
                y +=1;
            }
        }

        const center:sdl.PointF = .{.x=bug.x, .y=bug.y};
        const radius: f32 = 30.0;
        const color: sdl.Color = bug.brain.color;
        const opt: j2d.CircleOption = .{
                                        .thickness = 4,
                                        .num_segments = 16,
                                        .depth = 0.5,
                                    };
        try j2d.circle(
            center,
            radius,
            color,
            opt,
        );

    }
        const Gpos = cp.c.cpBodyGetPosition(GOD);
        const center:sdl.PointF = .{.x = Gpos.x, .y = Gpos.y};
        const radius: f32 = 30.0;
        const color: sdl.Color = .{.r=255, .g=255, .b=0};
        const opt: j2d.CircleOption = .{
                                        .thickness = 8,
                                        .num_segments = 8,
                                        .depth = 0.5,
                                    };
        try j2d.circle(
            center,
            radius,
            color,
            opt,
        );

    defer j2d.end();
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

