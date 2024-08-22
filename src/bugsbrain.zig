pub const std = @import("std");

const conf = @import("bugsconfig.zig");
const nn = @import("bugsnuron.zig");

// some inputs outputs and hiden layers basic struct
pub const Inputs = struct {nurons:[conf.maxIn] nn.Nuron};
pub const Outputs = struct {nurons:[conf.maxOut] nn.Nuron};
pub const Hidden = struct {nurons:[conf.maxHidden] nn.Nuron};


const brainSize = conf.maxIn + conf.maxHidden + conf.maxOut;
// the bug brain struct
pub const Brain = struct
{
    inputs: Inputs,
    hidden: Hidden,
    outputs: Outputs,

    size: usize = brainSize,

    ct: f32 = 0.1,



    pub fn update(self: *Brain)void
    {
        self.ct += 0.1;
        if(self.ct > 1.0)self.ct = 0.1;

        var inps = &self.inputs.nurons;
        var hids = &self.hidden.nurons;
        for(inps, 0..inps.len)|inp, i|
        {
            // _= inp;
            if(inp.neuronvalue > 0.9) hids[i].fire();
            inps[i].update();
        }
        for(hids, 0..hids.len)|hid, i|
        {
            _= hid;

            hids[i].update();
        }
    }



    pub fn mutate(self: *Brain)void
    {
        var cf: f32 = 0.01;
        var hidden = &self.hidden.nurons;
        for(hidden, 0..hidden.len)|nuron, i|
        {
            _= nuron;
           var cons = &hidden[i].cons;
           for(cons, 0..cons.len)|con,ii|
           {
                _=con;

                const seed: f32 = @floatFromInt(std.time.milliTimestamp() );

                // const random: f32 = self.ct ;
                cons[ii].weight = 1.0 /  seed / cf;
                cf += 1.0;
           }
        }
    }
};

