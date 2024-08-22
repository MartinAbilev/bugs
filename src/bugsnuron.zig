const conf = @import("bugsconfig.zig");
const print = @import("bugsshared.zig").print;
pub const Con = struct {to: usize, weight: f32, vw: f32 = undefined};

// the nuron struct
pub const Nuron = struct
{
    id: usize,
    x: f32,
    y: f32,
    z: f32,
    ntype: usize = 0,
    cons: [conf.maxCons] Con = undefined,
    neuronvalue: f32 = 0.1,
    thresold: f32 = 4.0,
    varsum: f32 = 0.1,
    pub fn conToAll(self: *Nuron) void
    {
        for(0..self.cons.len)|i|
        {
            const con: Con = Con{.to = i, .weight = 0.5};
            self.cons[i] = con;
        }
    }
    pub fn update(self: *Nuron) void
    {
        self.neuronvalue -=0.1;
        if(self.neuronvalue < 0.0) self.neuronvalue = 0.1;
    }
    pub fn fire(self: *Nuron) void
    {
        self.neuronvalue = 1.0;
        // print("nuron fired {}\n", .{self.id});
    }
    pub fn zero(self: *Nuron) void
    {
        self.neuronvalue = 0.0;
    }
};

