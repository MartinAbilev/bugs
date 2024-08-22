pub const std = @import("std");

const conf = @import("bugsconfig.zig");
const nn = @import("bugsnuron.zig");

const print = @import("bugsshared.zig").print;

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
            hids[i].varsum = 0.1;

            for(hid.cons, 0..hid.cons.len)|con, c|
            {
                _=c;
                // search for conected nuron need rework with pinter
                for(hids, 0..hids.len)|hd, hi|
                {
                    _=hi;
                    if(con.to == hd.id)
                    {
                        hids[i].varsum += hd.neuronvalue * con.weight;
                    }
                }
            }
            // when sum of all iputs reaches trezold fire nuron
            if( hids[i].varsum > hids[i].thresold )
            hids[i].fire();

            hids[i].update();
            self.ct += 1.0;
        }
    }
    pub fn mutate(self: *Brain)void
    {
        var hidden = &self.hidden.nurons;
        for(hidden, 0..hidden.len)|nuron, i|
        {
            _= nuron;
           var cons = &hidden[i].cons;
           for(cons, 0..cons.len)|con,ii|
           {
                _=con;
                const rand = std.crypto.random;
                const a = rand.float(f32);
                const b = rand.boolean();
                const c = rand.int(u8);
                const d = rand.intRangeAtMost(u8, 0, 255);

                const rnd = a;

                _ = .{ a, b, c, d };

                cons[ii].weight = rnd;
           }
           const rand = std.crypto.random;
           const a: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, 10) );
           hidden[i].thresold = a;
        }
        self.ct = 0.0;
    }
};

