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

const maxIn: usize = 4;
const maxOut: usize = 4;
const maxHidden: usize = 3*3;
const maxCons: usize = maxIn + maxOut + maxHidden;

var world: cp.World = undefined;

const Vec3 = struct {x: f32, y: f32, z: f32};

const Con = struct {to: usize, weight: f32};

const Nuron = struct
{
    id: usize,
    x: f32,
    y: f32,
    z: f32,
    cons: [maxCons] Con = undefined,
    neuronvalue: f32 = 0.1,
    fn conToAll(self: *Nuron) void
    {
        for(0..self.cons.len)|i|
        {
            const con: Con = Con{.to = i, .weight = 0.5};
            self.cons[i] = con;
        }
    }
    fn update(self: *Nuron, allnurons: []Nuron) void
    {
        // _=allnurons;
        var varsum: f32= 1.0;

        //  axson fires when all conected inputs value * weight  pass treasold 0.5
        for (self.cons, 0..self.cons.len) |con, i|
        {
            // _=con;
            // _=i;
            if(allnurons.len > i)
            {
                // print("all nuron id, totalneurons, counter i: {} {} {} {}\n", .{allnurons[i].id, allnurons.len, i, allnurons[i].neuronvalue});
                varsum = varsum * con.weight * allnurons[con.to].neuronvalue   ;
            }

        }
        if(varsum >= 0.5)
        {
            self.neuronvalue = 1.0;
        }
        else
        {
            self.neuronvalue = 0.1;
        }
        // print("varsum: {}\n", .{self.neuronvalue});
    }
    fn fire(self: *Nuron) void
    {
        self.neuronvalue = 1.0;
        print("nuron fired {}\n", .{self.id});
    }
};

const Inputs = struct {nurons:[maxIn] Nuron};
const Outputs = struct {nurons:[maxOut] Nuron};
const Hidden = struct {nurons:[maxHidden] Nuron};

const Brain = struct
{
    inputs: Inputs,
    hidden: Hidden,
    outputs: Outputs
};

const Bug =struct
{
    id: usize = 0,
    isAlive: bool = true,
    pid: usize = undefined, //  chips id
    x: f32,
    y: f32,
    z: f32,
    brain: Brain = undefined,
    pbody: ?*cp.c.cpBody = undefined,
    pshape: ?*cp.c.cpShape = undefined,
    pinp1: ?*cp.c.cpBody = undefined,
    pinp2: ?*cp.c.cpBody = undefined,
    pinp3: ?*cp.c.cpBody = undefined,
    pinp4: ?*cp.c.cpBody = undefined,
    // cords: Vec3,

    fn init(self: *Bug, ctx: jok.Context, id: usize) !void
    {
        _=ctx;
        //self.cords = Vec3 {.x = 1, .y = 1, .z = 1};
        self.id = id;

        var idc: usize= 0;

        var  in1 = Nuron{.id = idc, .x = 50, .y = 0, .z = 0}; idc = idc + 1 ;
        var  in2 = Nuron{.id = idc, .x = -50, .y = 0, .z = 0}; idc = idc + 1 ;
        var  in3 = Nuron{.id = idc, .x = 0, .y = 50, .z = 0}; idc = idc + 1 ;
        var  in4 = Nuron{.id = idc, .x = 0, .y = -50, .z = 0}; idc = idc + 1 ;

        var  on1 = Nuron{.id = idc, .x = 30, .y = 0, .z = 0}; idc = idc + 1 ;
        var  on2 = Nuron{.id = idc, .x = -30, .y = 0, .z = 0}; idc = idc + 1 ;
        var  on3 = Nuron{.id = idc, .x = 0, .y = 30, .z = 0}; idc = idc + 1 ;
        var  on4 = Nuron{.id = idc, .x = 0, .y = -30, .z = 0}; idc = idc + 1 ;

        var  hnn: [maxHidden]Nuron = undefined;
        for(0..maxHidden)|i|
        {
            const hn = Nuron{.id = idc, .x = 0, .y = 0, .z = 0};
            hnn[i] = hn;
            hnn[i].conToAll();
            idc = idc + 1 ;
        }

        in1.conToAll();
        in2.conToAll();
        in3.conToAll();
        in4.conToAll();

        on1.conToAll();
        on2.conToAll();
        on3.conToAll();
        on4.conToAll();

        const inputs   = Inputs{.nurons=[_]Nuron{in1, in2, in3, in4}};
        const outputs = Outputs{.nurons = [_]Nuron{on1, on2, on3, on4}};
        const hidden   = Hidden{.nurons = hnn};

        self.brain = Brain
        {
            .inputs = inputs,
            .outputs = outputs,
            .hidden = hidden
        };

        self.pid  = try world.addObject(.{
            .body = .{
                .dynamic = .{
                    .position = .{
                        .x = self.x,
                        .y = self.y,
                    },
                }
            },
            .shapes = &.{
                .{
                    .circle = .{
                        .radius = 15,
                        .physics = .{
                            .weight = .{ .mass = 1 },
                            .elasticity = 0.5,
                        },
                    },
                },
            },
        });
        self.pbody = world.objects.items[self.pid].body.?;
        cp.c.cpShapeSetCollisionType(world.objects.items[self.pid].shapes[0], 1);
        // Try cp.c.cpBodyGetPosition.
        // One more thing, world.objects.items[0].body is optional type, you might consider using .? operator to get real pointer.
        // const ctp = cp.c.cpShapeGetCollisionType(world.objects.items[self.pid].shapes[0]);
        // print("bug {} \n", .{ctp});

        const pid1 =  try world.addObject(.{
            .body = .{
                .dynamic = .{
                    .position = .{
                        .x = self.x + 0,
                        .y = self.y + 50,
                    },
                }
            },
            .shapes = &.{
                .{
                    .circle = .{
                        .radius = 5,
                        .physics = .{
                            .weight = .{ .mass = 1 },
                            .elasticity = 0.5,
                        },
                    },
                },
            },
        });
        self.pinp1 = world.objects.items[pid1].body.?;
        cp.c.cpShapeSetSensor(world.objects.items[pid1].shapes[0], cp.c.cpTrue);
        bs.constrain(world, self.pbody, self.pinp1);

        const pid2 =  try world.addObject(.{
            .body = .{
                .dynamic = .{
                    .position = .{
                        .x = self.x + 0,
                        .y = self.y - 50,
                    },
                }
            },
            .shapes = &.{
                .{
                    .circle = .{
                        .radius = 5,
                        .physics = .{
                            .weight = .{ .mass = 1 },
                            .elasticity = 0.5,
                        },
                    },
                },
            },
        });
        self.pinp2 = world.objects.items[pid2].body.?;
        cp.c.cpShapeSetSensor(world.objects.items[pid2].shapes[0], cp.c.cpTrue);
        bs.constrain(world, self.pbody, self.pinp2);

        const pid3 =  try world.addObject(.{
            .body = .{
                .dynamic = .{
                    .position = .{
                        .x = self.x + 50,
                        .y = self.y + 0,
                    },
                }
            },
            .shapes = &.{
                .{
                    .circle = .{
                        .radius = 5,
                        .physics = .{
                            .weight = .{ .mass = 1 },
                            .elasticity = 0.5,
                        },
                    },
                },
            },
        });
        self.pinp3 = world.objects.items[pid3].body.?;
        cp.c.cpShapeSetSensor(world.objects.items[pid3].shapes[0], cp.c.cpTrue);
        bs.constrain(world, self.pbody, self.pinp3);

        const pid4 =  try world.addObject(.{
            .body = .{
                .dynamic = .{
                    .position = .{
                        .x = self.x - 50,
                        .y = self.y + 0,
                    },
                },
            },
            .shapes = &.{
                .{
                    .circle = .{
                        .radius = 5,
                        .physics = .{
                            .weight = .{ .mass = 1 },
                            .elasticity = 0.5,
                        },
                    },
                },
            },
        });
        self.pinp4 = world.objects.items[pid4].body.?;
        cp.c.cpShapeSetSensor(world.objects.items[pid4].shapes[0], cp.c.cpTrue);

        bs.constrain(world,self.pbody, self.pinp4);
        bs.constrain(world,self.pinp1, self.pinp4);
        bs.constrain(world,self.pinp2, self.pinp3);
        bs.constrain(world,self.pinp3, self.pinp4);

        cp.c.cpBodySetMyUserData(self.pbody, .{.id=self.id, .inp = 0});
        cp.c.cpBodySetMyUserData(self.pinp1, .{.id=self.id, .inp = 0});
        cp.c.cpBodySetMyUserData(self.pinp2, .{.id=self.id, .inp = 1});
        cp.c.cpBodySetMyUserData(self.pinp3, .{.id=self.id, .inp = 2});
        cp.c.cpBodySetMyUserData(self.pinp4, .{.id=self.id, .inp = 3});

    }
    fn update(self: *Bug) void
    {

        for (self.brain.hidden.nurons, 0..self.brain.hidden.nurons.len) |nuron,i|
        {
            _=nuron;
            self.brain.hidden.nurons[i].update(&self.brain.hidden.nurons);
        }

        const pinp1 = cp.c.cpBodyGetPosition(self.pinp1);
        self.brain.inputs.nurons[0].x = pinp1.x;
        self.brain.inputs.nurons[0].y = pinp1.y;

        const pinp2 = cp.c.cpBodyGetPosition(self.pinp2);
        self.brain.inputs.nurons[1].x = pinp2.x;
        self.brain.inputs.nurons[1].y = pinp2.y;

        const pinp3 = cp.c.cpBodyGetPosition(self.pinp3);
        self.brain.inputs.nurons[2].x = pinp3.x;
        self.brain.inputs.nurons[2].y = pinp3.y;

        const pinp4 = cp.c.cpBodyGetPosition(self.pinp4);
        self.brain.inputs.nurons[3].x = pinp4.x;
        self.brain.inputs.nurons[3].y = pinp4.y;

        const b =   self.pbody;
        const bv = cp.c.cpBodyGetPosition(b);

        const px: f32 = bv.x;
        const py: f32 = bv.y;

        // print("bug {} x, y: {}, {}\n", .{self.id, px, py});

        self.x = px;
        self.y = py;

    }
    fn fire(self: *Bug, id: usize) void
    {
        self.brain.inputs.nurons[id].fire();
    }
    fn die(self: *Bug) void
    {
        self.isAlive = false;

        const kur = cp.c.cpv(0.0, 1000.0);
        cp.c.cpBodySetPosition(self.pbody, kur);
        cp.c.cpBodySetPosition(self.pinp1, kur);
        cp.c.cpBodySetPosition(self.pinp2, kur);
        cp.c.cpBodySetPosition(self.pinp3, kur);
        cp.c.cpBodySetPosition(self.pinp4, kur);

        print("Bug {} DIE!\n", .{self.id});
    }
};

var Bugs :[3] Bug= undefined;

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

    world = try cp.World.init(ctx.allocator(), .{
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
    const handler = cp.c.cpSpaceAddCollisionHandler(world.space, 1, 0);
    handler.*.postSolveFunc = postSolve;

    const handler2 = cp.c.cpSpaceAddCollisionHandler(world.space, 0, 0);
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
        const b = Bug{.x=x , .y=y, .z=0};
        Bugs[i] = b;
        try Bugs[i].init(ctx, i);
    }

    _ = try world.addObject(.{
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
    world.update(ctx.deltaSeconds());
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
    try world.debugDraw(ctx.renderer());

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
    world.deinit();

    for(0..svg.len)|i|
    {
        svg[i].destroy();
        tex[i].destroy();
    }
}

