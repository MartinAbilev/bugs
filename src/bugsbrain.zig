pub const std = @import("std");

const conf = @import("bugsconfig.zig");
const nn = @import("bugsnuron.zig");

const bb: type = @import("bugsbug.zig");
const cp = @import("bugsshared.zig").cp;
const j2d = @import("bugsshared.zig").j2d;
const sdl = @import("bugsshared.zig").sdl;

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
    color: sdl.Color = .{ .r = 255, .g =255, .b = 255 },

    pub fn update(self: *Brain, fire: fn(self: *bb.Bug, id: usize)void, bself: *bb.Bug)void
    {


        const inps = &self.inputs.nurons;
        var hids = &self.hidden.nurons;
        var outs = &self.outputs.nurons;
        for(inps, 0..inps.len)|inp, i|
        {
            // _= inp;
            // if(inp.neuronvalue>inp.thresold)
            if(inp.neuronvalue>0.9)
            {
                for(inp.cons)|con|
                {
                    self.hidden.nurons[con.to].neuronvalue=inp.neuronvalue * con.weight;
                }
            }
            else
            {
                self.inputs.nurons[i].zero();
            }
            self.inputs.nurons[i].update();

        }
        for(hids, 0..hids.len)|hid, i|
        {
            hids[i].varsum = 0.0;

            for(hid.cons, 0..hid.cons.len)|con, c|
            {
                _=c;
                // search for conected nuron need rework with pinter

                    self.hidden.nurons[i].varsum += hids[con.to].neuronvalue * con.weight;

            }
            // hids[i].varsum = hids[i].varsum / hid.cons.len;
            // when sum of all iputs reaches trezold fire nuron
            if( hids[i].varsum > hids[i].thresold )
            {
                // print("hidden value is greater tha zero: {}\n", .{hids[i].varsum});
                self.hidden.nurons[i].fire();
            }
            else
            {
                self.hidden.nurons[i].zero();
            }
            self.hidden.nurons[i].update();

        }

        for(outs, 0..outs.len)|out, i|
        {
            outs[i].varsum = 0.0;

            for(out.cons, 0..out.cons.len)|con, c|
            {
                _=c;
                if(con.to < hids.len)
                {
                    outs[i].varsum += hids[con.to].neuronvalue * con.weight;
                }
            }
            // outs[i].varsum = outs[i].varsum / out.cons.len;

            // when sum of all iputs reaches trezold fire nuron
            if( outs[i].varsum > outs[i].thresold )
            {
                fire(bself, i);
                outs[i].fire();
            }
            else
            {
                outs[i].zero();
            }
            outs[i].update();
        }
    }
    pub fn mutate(self: *Brain)void
    {
        const rand = std.crypto.random;
        const raternd: f32 = @floatFromInt( rand.intRangeAtMost(u8, 0, conf.maxMutRate) );
        const rate: f32 = raternd;
        var hidden = &self.hidden.nurons;
        for(hidden, 0..hidden.len)|nuron, i|
        {
            _= nuron;
           var cons = &hidden[i].cons;
           for(cons, 0..cons.len)|con,ii|
           {
                _=con;
                // const a = rand.float(f32);
                const b = rand.boolean();
                // const c = rand.int(u8);
                // const d = rand.intRangeAtMost(u8, 0, 255);

                const rnd: f32 = @floatFromInt( rand.intRangeAtMost(u8, 0, 100) );

                if(b)cons[ii].weight += rnd/100*rate;
                if(!b)cons[ii].weight -= rnd/100*rate;
           }
           const a: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, 100) );
           const b = rand.boolean();

           if(b)hidden[i].thresold += a/100*rate;
           if(!b)hidden[i].thresold -= a/100*rate;
           if(hidden[i].thresold < 0)hidden[i].thresold = 0.0;
        }

        var outputs = &self.outputs.nurons;
        for(outputs, 0..outputs.len)|nuron, i|
        {
            _= nuron;
           var cons = &outputs[i].cons;
           for(cons, 0..cons.len)|con,ii|
           {
                _=con;
                // const a = rand.float(f3);
                const b = rand.boolean();

                const rnd: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, 100) );

                if(b)cons[ii].weight += rnd/100*rate;
                if(!b)cons[ii].weight -= rnd/100*rate;
           }
           const a: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, 100) );
           const b = rand.boolean();
           if(b)outputs[i].thresold += a/100*rate;
           if(!b)outputs[i].thresold -= a/100*rate;
        }

        var inputs = &self.inputs.nurons;
        for(inputs, 0..inputs.len)|nuron, i|
        {
            _= nuron;
           var cons = &inputs[i].cons;
           for(cons, 0..cons.len)|con,ii|
           {
                _=con;
                // const a = rand.float(f32);
                const b = rand.boolean();
                // const c = rand.int(u8);
                const d: f32 = @floatFromInt( rand.intRangeAtMost(u8, 0, 100) );

                if(b)cons[ii].weight += d/100*rate;
                if(!b)cons[ii].weight -= d/100*rate;
           }
           const a: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, 100) );
           const b = rand.boolean();
           if(b)inputs[i].thresold += a/100*rate;
           if(!b)inputs[i].thresold -= a/100*rate;
        }
    }


};

