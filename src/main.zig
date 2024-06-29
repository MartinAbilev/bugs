const std = @import("std");
const jok = @import("jok");

const sdl = jok.sdl;
const font = jok.font;
const j2d = jok.j2d;
const print = std.debug.print;

var svg: jok.svg.SvgBitmap = undefined;
var tex: sdl.Texture = undefined;

const maxIn: usize = 4;
const maxOut: usize = 4;
const maxHidden: usize = 3*3;
const maxCons: usize = maxIn + maxOut + maxHidden;

const Vec3 = struct {x: f32, y: f32, z: f32};

const Con = struct {to: usize, weight: f32};

const Nuron = struct
{
    id: usize,
    x: f32,
    y: f32,
    z: f32,
    cons: [maxCons] Con = undefined,
    fn conToAll(self: *Nuron) void
    {
        for(0..self.cons.len)|i|
        {
            const con: Con = Con{.to = i, .weight = 0.5};
            self.cons[i] = con;
        }
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
    x: f32,
    y: f32,
    z: f32,
    brain: Brain = undefined,
    // cords: Vec3,

    fn init(self: *Bug, id: usize) void
    {
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
    }
};

var Bugs :[3] Bug= undefined;

pub fn init(ctx: jok.Context) !void
{
    // _ = ctx;
    std.log.info("game init", .{});

        svg = try jok.svg.createBitmapFromFile(
        ctx.allocator(),
        "assets/bug.svg",
        .{},
    );

    tex = try jok.utils.gfx.createTextureFromPixels(
        ctx,
        svg.pixels,
        svg.format,
        .static,
        svg.width,
        svg.height,
    );

    for(0..Bugs.len)|i|
    {
        const ii: f32 = @floatFromInt(i);
        const b = Bug{.x=100 * ii , .y=100 * ii, .z=0};
        Bugs[i] = b;
        Bugs[i].init(i);
    }

    for (Bugs, 0..) |elem, i|
    {
        std.log.info("id: {}, bug: {}\n", .{i, elem});
    }
}

pub fn event(ctx: jok.Context, e: sdl.Event) !void {
    _ = ctx;
    _ = e;
}

pub fn update(ctx: jok.Context) !void {
    _ = ctx;
}

pub fn draw(ctx: jok.Context) !void {
    ctx.clear(null);

    // const size = ctx.getCanvasSize();
    // const rect_color = sdl.Color.rgba(0, 128, 0, 120);
    // var area: sdl.RectangleF = undefined;
    // var atlas: *font.Atlas = undefined;

    j2d.begin(.{ .depth_sort = .back_to_forth });
    defer j2d.end();

    for(Bugs)|bug|
    {

        try j2d.image(
            tex,
            .{
                .x = ctx.getCanvasSize().x / 2 + bug.x,
                .y = ctx.getCanvasSize().y / 2 + bug.y,
            },
            .{
                .rotate_degree = ctx.seconds() * 60 + bug.x,
                .scale =.{.x = 0.1, .y = 0.1},
                .anchor_point = .{ .x = 0.5, .y = 0.5 },
            },
        );

    }

    // atlas = try font.DebugFont.getAtlas(ctx, 20);
    // try j2d.text(
    //     .{
    //         .atlas = atlas,
    //         .pos = .{ .x = 0, .y = 0 },
    //         .ypos_type = .top,
    //         .tint_color = sdl.Color.cyan,
    //     },
    //     "ABCDEFGHIJKL abcdefghijkl",
    //     .{},
    // );
    // area = try atlas.getBoundingBox(
    //     "ABCDEFGHIJKL abcdefghijkl",
    //     .{ .x = 0, .y = 0 },
    //     .top,
    //     .aligned,
    // );
    // try j2d.rectFilled(area, rect_color, .{});
}

pub fn quit(ctx: jok.Context) void {
    _ = ctx;
    std.log.info("game quit", .{});

    svg.destroy();
    tex.destroy();
}

