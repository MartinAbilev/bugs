const conf = @import("bugsconfig.zig");
const nn = @import("bugsnuron.zig");

// some inputs outputs and hiden layers basic struct
pub const Inputs = struct {nurons:[conf.maxIn] nn.Nuron};
pub const Outputs = struct {nurons:[conf.maxOut] nn.Nuron};
pub const Hidden = struct {nurons:[conf.maxHidden] nn.Nuron};

// the bug brain struct 
pub const Brain = struct
{
    inputs: Inputs,
    hidden: Hidden,
    outputs: Outputs
};
