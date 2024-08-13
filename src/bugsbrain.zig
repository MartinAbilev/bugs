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

    nurons: [brainSize]nn.Nuron = undefined,

    pub fn update(self: *Brain)void
    {

        for(self.inputs.nurons) |inp|
        {
            for(inp.cons) |con|
            {
                const conto = con.to;
                const weight = con.weight;

                for(0..self.hidden.nurons.len)|i|
                {
                    if(self.hidden.nurons[i].id == conto)
                    {
                        self.hidden.nurons[i].neuronvalue = 666 * weight;
                    }
                }
            }
        }

    }
};

