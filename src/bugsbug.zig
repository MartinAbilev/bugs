// The BUG main struct to doos later to sep file
const br = @import("bugsbrain.zig");

const conf = @import("bugsconfig.zig");
const Nuron = @import("bugsnuron.zig").Nuron;

const cp = @import("bugsshared.zig").cp;
const constrain = @import("bugsshared.zig").constrain;
const print = @import("bugsshared.zig").print;
const jok = @import("bugsshared.zig").jok;

// the World todoos later move to sep file
pub var world: cp.World = undefined;

pub const Bug =struct
{
    id: usize = 0,
    isAlive: bool = true,
    pid: usize = undefined, //  chips id
    x: f32,
    y: f32,
    z: f32,
    brain: br.Brain = undefined,
    pbody: ?*cp.c.cpBody = undefined,
    pshape: ?*cp.c.cpShape = undefined,
    pinp1: ?*cp.c.cpBody = undefined,
    pinp2: ?*cp.c.cpBody = undefined,
    pinp3: ?*cp.c.cpBody = undefined,
    pinp4: ?*cp.c.cpBody = undefined,
    // cords: Vec3,

    pub fn init(self: *Bug, ctx: jok.Context, id: usize) !void
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

        var  hnn: [conf.maxHidden]Nuron = undefined;
        for(0..conf.maxHidden)|i|
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

        const inputs   = br.Inputs{.nurons=[_]Nuron{in1, in2, in3, in4}};
        const outputs = br.Outputs{.nurons = [_]Nuron{on1, on2, on3, on4}};
        const hidden   = br.Hidden{.nurons = hnn};

        self.brain = br.Brain
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
        constrain(world, self.pbody, self.pinp1);

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
        constrain(world, self.pbody, self.pinp2);

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
        constrain(world, self.pbody, self.pinp3);

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

        constrain(world,self.pbody, self.pinp4);
        constrain(world,self.pinp1, self.pinp4);
        constrain(world,self.pinp2, self.pinp3);
        constrain(world,self.pinp3, self.pinp4);

        cp.c.cpBodySetMyUserData(self.pbody, .{.id=self.id, .inp = 0});
        cp.c.cpBodySetMyUserData(self.pinp1, .{.id=self.id, .inp = 0});
        cp.c.cpBodySetMyUserData(self.pinp2, .{.id=self.id, .inp = 1});
        cp.c.cpBodySetMyUserData(self.pinp3, .{.id=self.id, .inp = 2});
        cp.c.cpBodySetMyUserData(self.pinp4, .{.id=self.id, .inp = 3});

    }
    pub fn update(self: *Bug) void
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
    pub fn fire(self: *Bug, id: usize) void
    {
        self.brain.inputs.nurons[id].fire();
    }
    pub fn die(self: *Bug) void
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