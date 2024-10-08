pub const std = @import("std");

pub const br = @import("bugsbrain.zig");

const conf = @import("bugsconfig.zig");
pub const Nuron = @import("bugsnuron.zig").Nuron;

const cp = @import("bugsshared.zig").cp;
const sdl = @import("bugsshared.zig").sdl;
const constrain = @import("bugsshared.zig").constrain;
const print = @import("bugsshared.zig").print;
const jok = @import("bugsshared.zig").jok;

// the World
pub var world: cp.World = undefined;

// The BUG main struct
pub const Bug =struct
{
    id: usize = 0,
    isAlive: bool = true,
    pid: usize = undefined, //  chips id
    x: f32,
    y: f32,
    z: f32,
    ct: i64 = 0,


    brain: br.Brain = undefined,
    pbody: ?*cp.c.cpBody = undefined,
    pshape: ?*cp.c.cpShape = undefined,
    pinp1: ?*cp.c.cpBody = undefined,
    pinp2: ?*cp.c.cpBody = undefined,
    pinp3: ?*cp.c.cpBody = undefined,
    pinp4: ?*cp.c.cpBody = undefined,

    pub fn init(self: *Bug, ctx: jok.Context, id: usize) !void
    {
        _=ctx;
        self.id = id;

        var idc: usize= 0;

        var  in01 = Nuron{.id = idc, .x = 50, .y = 0, .z = 0, .ntype = 1, }; idc = idc + 1 ;
        var  in02 = Nuron{.id = idc, .x = -50, .y = 0, .z = 0, .ntype = 1, }; idc = idc + 1 ;
        var  in03 = Nuron{.id = idc, .x = 0, .y = 50, .z = 0, .ntype = 1, }; idc = idc + 1 ;
        var  in04 = Nuron{.id = idc, .x = 0, .y = -50, .z = 0, .ntype = 1, }; idc = idc + 1 ;

        // for velosity check
        var  in05 = Nuron{.id = idc, .x = 0, .y = 0, .z = 0, .ntype = 1, }; idc = idc + 1 ;
        var  in06 = Nuron{.id = idc, .x = 0, .y = 0, .z = 0, .ntype = 1, }; idc = idc + 1 ;
        var  in07 = Nuron{.id = idc, .x = 0, .y = 0, .z = 0, .ntype = 1, }; idc = idc + 1 ;
        var  in08 = Nuron{.id = idc, .x = 0, .y = 0, .z = 0, .ntype = 1, }; idc = idc + 1 ;

        // for angular velocity check
        var  in09 = Nuron{.id = idc, .x = 0, .y = 0, .z = 0, .ntype = 1, }; idc = idc + 1 ;
        var  in10 = Nuron{.id = idc, .x = 0, .y = 0, .z = 0, .ntype = 1, }; idc = idc + 1 ;

        var  on1 = Nuron{.id = idc, .x = 30, .y = 0, .z = 0, .ntype = 2, }; idc = idc + 1 ;
        var  on2 = Nuron{.id = idc, .x = -30, .y = 0, .z = 0, .ntype = 2, }; idc = idc + 1 ;
        var  on3 = Nuron{.id = idc, .x = 0, .y = 30, .z = 0, .ntype = 2, }; idc = idc + 1 ;
        var  on4 = Nuron{.id = idc, .x = 0, .y = -30, .z = 0, .ntype = 2, }; idc = idc + 1 ;
        var  on5 = Nuron{.id = idc, .x = 0, .y = 30, .z = 0, .ntype = 2, }; idc = idc + 1 ;
        var  on6 = Nuron{.id = idc, .x = 0, .y = -30, .z = 0, .ntype = 2, }; idc = idc + 1 ;

        var  hnn: [conf.maxHidden]Nuron = undefined;
        for(0..conf.maxHidden)|i|
        {
            const hn = Nuron{.id = idc, .x = 0, .y = 0, .z = 0};
            hnn[i] = hn;
            hnn[i].conToAll();
            idc = idc + 1 ;
        }

        in01.conToAll();
        in02.conToAll();
        in03.conToAll();
        in04.conToAll();

        in05.conToAll();
        in06.conToAll();
        in07.conToAll();
        in08.conToAll();

        in09.conToAll();
        in10.conToAll();

        on1.conToAll();
        on2.conToAll();
        on3.conToAll();
        on4.conToAll();
        on5.conToAll();
        on6.conToAll();

        const inputs   = br.Inputs
        {.nurons=[_]Nuron{in01, in02, in03, in04, in05, in06, in07, in08, in09, in10}};

        const outputs = br.Outputs
        {.nurons = [_]Nuron{on1, on2, on3, on4, on5, on6}};
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
                cp.c.cpShapeSetCollisionType(world.objects.items[pid1].shapes[0], 3);

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
                cp.c.cpShapeSetCollisionType(world.objects.items[pid2].shapes[0], 3);

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
                cp.c.cpShapeSetCollisionType(world.objects.items[pid3].shapes[0], 3);

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
                cp.c.cpShapeSetCollisionType(world.objects.items[pid4].shapes[0], 3);


        constrain(world,self.pbody, self.pinp4);
        constrain(world,self.pinp1, self.pinp4);
        constrain(world,self.pinp2, self.pinp3);
        constrain(world,self.pinp3, self.pinp4);
        constrain(world,self.pinp1, self.pinp3);
        constrain(world,self.pinp2, self.pinp4);

        cp.c.cpBodySetMyUserData(self.pbody, .{.id=self.id, .inp = 0});
        cp.c.cpBodySetMyUserData(self.pinp1, .{.id=self.id, .inp = 0});
        cp.c.cpBodySetMyUserData(self.pinp2, .{.id=self.id, .inp = 1});
        cp.c.cpBodySetMyUserData(self.pinp3, .{.id=self.id, .inp = 2});
        cp.c.cpBodySetMyUserData(self.pinp4, .{.id=self.id, .inp = 3});
    }
    pub fn fireTruster(self: *Bug, id: usize) void
    {
        // print("fire", .{});
        // const bodyPos = cp.c.cpBodyGetPosition(self.pbody);
        var cx: f32 = 0.0;
        var cy: f32 = 0.0;

        // const locp = cp.c.cpBodyWorldToLocal(self.pbody, cp.c.cpBodyGetPosition(self.pinp1));
        const locp = cp.c.cpBodyWorldToLocal(self.pbody, cp.c.cpv(self.brain.outputs.nurons[id].x, self.brain.outputs.nurons[id].y));
        var force = cp.c.cpv(-locp.x*0.5, -locp.y*0.5);
        var bodyPos = cp.c.cpv(cx, cy);        // const impos = cp.c.cpBodyGetPosition(self.pinp3);
        if(id == 4)
        {
            cx = 0.0;
            cy = -10.0;
            force = cp.c.cpv(1, cy);
            bodyPos = cp.c.cpv(cx, cy);
                    cp.c.cpBodyApplyImpulseAtLocalPoint(self.pbody,
                                            force,
                                            bodyPos,
                                            );
                                                        cx = 0.0;
            cx = 0.0;
            cy = 10.0;
            force = cp.c.cpv(-1, cy);
            bodyPos = cp.c.cpv(cx, cy);
                    cp.c.cpBodyApplyImpulseAtLocalPoint(self.pbody,
                                            force,
                                            bodyPos,
                                            );
        }
        else
        if(id == 5)
        {
            cx = 0.0;
            cy = -10.0;
            force = cp.c.cpv(-1, cy);
            bodyPos = cp.c.cpv(cx, cy);
                    cp.c.cpBodyApplyImpulseAtLocalPoint(self.pbody,
                                            force,
                                            bodyPos,
                                            );
            cx = 0.0;
            cy = 10.0;
            force = cp.c.cpv(1, cy);
            bodyPos = cp.c.cpv(cx, cy);
                    cp.c.cpBodyApplyImpulseAtLocalPoint(self.pbody,
                                            force,
                                            bodyPos,
                                            );
        }
        else
        cp.c.cpBodyApplyImpulseAtLocalPoint(self.pbody,
                                            force,
                                            bodyPos,
                                            );
    }
    pub fn update(self: *Bug, bestTime: *i64, championBrain: *br.Brain) void
    {
        self.brain.update(fireTruster , self);

        const pinp1 = cp.c.cpBodyGetPosition(self.pinp1);
        self.brain.inputs.nurons[0].x = pinp1.x;
        self.brain.inputs.nurons[0].y = pinp1.y;
        self.brain.outputs.nurons[0].x = pinp1.x;
        self.brain.outputs.nurons[0].y = pinp1.y;

        const pinp2 = cp.c.cpBodyGetPosition(self.pinp2);
        self.brain.inputs.nurons[1].x = pinp2.x;
        self.brain.inputs.nurons[1].y = pinp2.y;
        self.brain.outputs.nurons[1].x = pinp2.x;
        self.brain.outputs.nurons[1].y = pinp2.y;

        const pinp3 = cp.c.cpBodyGetPosition(self.pinp3);
        self.brain.inputs.nurons[2].x = pinp3.x;
        self.brain.inputs.nurons[2].y = pinp3.y;
        self.brain.outputs.nurons[2].x = pinp3.x;
        self.brain.outputs.nurons[2].y = pinp3.y;

        const pinp4 = cp.c.cpBodyGetPosition(self.pinp4);
        self.brain.inputs.nurons[3].x = pinp4.x;
        self.brain.inputs.nurons[3].y = pinp4.y;
        self.brain.outputs.nurons[3].x = pinp4.x;
        self.brain.outputs.nurons[3].y = pinp4.y;

        self.brain.outputs.nurons[4].x = pinp4.x;
        self.brain.outputs.nurons[4].y = pinp4.y;

        self.brain.outputs.nurons[5].x = pinp3.x;
        self.brain.outputs.nurons[5].y = pinp3.y;

        const b =   self.pbody;
        const bv = cp.c.cpBodyGetPosition(b);

        const px: f32 = bv.x;
        const py: f32 = bv.y;


        const velocity = cp.c.cpBodyGetVelocity(self.pbody);
        const angularVelocity = cp.c.cpBodyGetAngularVelocity(self.pbody);

        // print("linear velocity: {}\n", .{velocity});
        // print("angular velocity: {}\n", .{angularVelocity});
       if( self.brain.inputs.nurons[4].neuronvalue == 0 and velocity.x > 6) self.brain.inputs.nurons[4].neuronvalue = velocity.x
       else self.brain.inputs.nurons[4].neuronvalue = 0.0;

       if( self.brain.inputs.nurons[5].neuronvalue == 0 and velocity.x < -6) self.brain.inputs.nurons[5].neuronvalue = -1*velocity.x
       else self.brain.inputs.nurons[5].neuronvalue = 0.0;

       if( self.brain.inputs.nurons[6].neuronvalue == 0 and velocity.y > 6) self.brain.inputs.nurons[6].neuronvalue = velocity.y
       else self.brain.inputs.nurons[6].neuronvalue = 0.0;

       if( self.brain.inputs.nurons[7].neuronvalue == 0 and velocity.y < -6) self.brain.inputs.nurons[7].neuronvalue = -1*velocity.y
       else self.brain.inputs.nurons[7].neuronvalue = 0.0;


       if( self.brain.inputs.nurons[8].neuronvalue == 0 and angularVelocity > 3) self.brain.inputs.nurons[8].neuronvalue = angularVelocity
       else self.brain.inputs.nurons[8].neuronvalue = 0;

       if( self.brain.inputs.nurons[9].neuronvalue == 0 and angularVelocity < -3) self.brain.inputs.nurons[9].neuronvalue = -1*angularVelocity
       else self.brain.inputs.nurons[9].neuronvalue = 0;


        self.x = px;
        self.y = py;
        self.ct += 1;
        if(self.ct > bestTime.*)
        {
            bestTime.* = self.ct;
            const rand = std.crypto.random;

                const cr = rand.intRangeAtMost(u8, 0, 255);
                const cg = rand.intRangeAtMost(u8, 0, 255);
                const cb = rand.intRangeAtMost(u8, 0, 255);

            const newChampionColor: sdl.Color = .{ .r = cr, .g =cg, .b = cb };

            championBrain.* = self.brain;
            championBrain.*.color = newChampionColor;

            // print("best time is: {}\n", .{bestTime.*});
        }
    }

    pub fn fire(self: *Bug, id: usize) void
    {
        const inps = &self.brain.inputs.nurons;
        for(0..inps.len)|ii|
        {
            if(id == inps[ii].id)
            {
                // print("Fire Input Nuron {}\n", .{id});
                inps[ii].fire();
            }
        }
        const hids = &self.brain.hidden.nurons;
        for(0..hids.len)|ii|
        {
            if(id == hids[ii].id)
            {
                print("Fire Hidden Nuron {}\n", .{id});
                hids[ii].fire();
            }
        }
        const outs = &self.brain.outputs.nurons;
        for(0..outs.len)|ii|
        {
            if(id == outs[ii].id)
            {
                print("Fire Output Nuron {}\n", .{id});
                fireTruster(self, ii);
                outs[ii].fire();
            }
        }

    }
    pub fn mutate(self: *Bug) void
    {
        self.brain.mutate();
    }
    pub fn die(self: *Bug, championBrain: *br.Brain) void
    {
        // _=self;
        self.isAlive = false;

        const rand = std.crypto.random;

        const rx: f32=  @floatFromInt(rand.intRangeAtMost(u16, 50, 750));
        const ry: f32=  @floatFromInt(rand.intRangeAtMost(u16, 50, 550));

        const kur = cp.c.cpv(rx, ry);

        cp.c.cpBodySetVelocity(self.pbody, cp.c.cpv(0,0));
        cp.c.cpBodySetAngularVelocity(self.pbody, 0.0);
        cp.c.cpBodySetVelocity(self.pinp1, cp.c.cpv(10,10));
        cp.c.cpBodySetVelocity(self.pinp2, cp.c.cpv(10,10));
        cp.c.cpBodySetVelocity(self.pinp3, cp.c.cpv(10,10));
        cp.c.cpBodySetVelocity(self.pinp4, cp.c.cpv(10,10));

        cp.c.cpBodySetPosition(self.pbody, kur);
        cp.c.cpBodySetPosition(self.pinp1, cp.c.cpv(kur.x+50, kur.y));
        cp.c.cpBodySetPosition(self.pinp2, cp.c.cpv(kur.x-50, kur.y));
        cp.c.cpBodySetPosition(self.pinp3, cp.c.cpv(kur.x, kur.y+50));
        cp.c.cpBodySetPosition(self.pinp4, cp.c.cpv(kur.x, kur.y-50));

        self.ct = 0;
        self.brain = championBrain.*;

        for(0..self.brain.inputs.nurons.len)|i|
        {
            self.brain.inputs.nurons[i].neuronvalue =0.0;
        }
        for(0..self.brain.hidden.nurons.len)|i|
        {
            self.brain.hidden.nurons[i].zero();
        }
        for(0..self.brain.outputs.nurons.len)|i|
        {
            self.brain.outputs.nurons[i].zero();
        }
        mutate(self);

       // print("Bug {} DIE!\n", .{self.id});
    }

};
