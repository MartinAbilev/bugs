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

    pub fn update(self: *Brain, fireTruster: fn(self: *bb.Bug, id: usize)void, bself: *bb.Bug)void
    {
        const inps = &self.inputs.nurons;
        var hids = &self.hidden.nurons;
        var outs = &self.outputs.nurons;

        for(inps, 0..inps.len)|inp, i|
        {

            if(inp.neuronvalue >= 1.0)
            {
                for(inp.cons)|con|
                {
                    if(1.0 * con.weight > 0)hids[con.to].neuronvalue = inp.neuronvalue;
                }

            }
            else
            {

                inps[i].zero();
            }

            inps[i].update();
        }

        for(hids, 0..hids.len)|hid, i|
        {
            hids[i].varsum = 0.0;
            for(hid.cons, 0..hid.cons.len)|con, c|
            {
                _=c;
                hids[i].varsum += hids[con.to].neuronvalue * con.weight;
            }
            // when sum of all conected hids reaches trezold fire nuron
            if( hids[i].varsum > hid.thresold ) // dont use here hid from  for loop cuz it not mutate!!
            {
               hids[i].fire();
            }
            else
            {
                hids[i].zero();
            }

            hids[i].update();
        }

        for(outs, 0..outs.len)|out, i|
        {
            outs[i].varsum = 0.0;
            for(out.cons, 0..out.cons.len)|con, c|
            {
                _=c;
                outs[i].varsum += hids[con.to].neuronvalue * con.weight;
            }
            // when sum of all iputs reaches trezold fire nuron
            if( outs[i].varsum > out.thresold )
            {
                // _=bself;
                // _=fireTruster;
                fireTruster(bself, i);
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
        const raternd: f32 =
        @floatFromInt( rand.intRangeAtMost(u8, 0, conf.maxMutRate) );
        const rate: f32 = raternd;

        var hidden = &self.hidden.nurons;
        for(hidden, 0..hidden.len)|nuron, i|
        {
            _= nuron;
           var cons = &hidden[i].cons;
           for(cons, 0..cons.len)|con,ii|
           {
                _=con;
                const b = rand.boolean();

                const rnd: f32 = @floatFromInt( rand.intRangeAtMost(u8, 0, conf.maxMutRate) );

                if(b)cons[ii].weight += rnd/conf.maxMutRate*rate;
                if(!b)cons[ii].weight -= rnd/conf.maxMutRate*rate;
           }
           const a: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, conf.maxMutRate) );
           const b = rand.boolean();

           if(b)hidden[i].thresold += a/conf.maxMutRate*rate;
           if(!b and hidden[i].thresold > 0)hidden[i].thresold -= a/conf.maxMutRate*rate;
        }

        var outputs = &self.outputs.nurons;
        for(outputs, 0..outputs.len)|nuron, i|
        {
            _= nuron;
           var cons = &outputs[i].cons;
           for(cons, 0..cons.len)|con,ii|
           {
                _=con;
                const b = rand.boolean();

                const rnd: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, conf.maxMutRate) );

                if(b)cons[ii].weight += rnd/conf.maxMutRate*rate;
                if(!b)cons[ii].weight -= rnd/conf.maxMutRate*rate;
           }
           const a: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, conf.maxMutRate) );
           const b = rand.boolean();
           if(b and outputs[i].thresold<0.9)outputs[i].thresold += a/conf.maxMutRate*rate;
           if(!b and outputs[i].thresold>0)outputs[i].thresold -= a/conf.maxMutRate*rate;
        }

        var inputs = &self.inputs.nurons;
        for(inputs, 0..inputs.len)|nuron, i|
        {
            _= nuron;
           var cons = &inputs[i].cons;
           for(cons, 0..cons.len)|con,ii|
           {
                _=con;
                // const b = rand.boolean();
                // const c = rand.int(u8);
                // const d: f32 = @floatFromInt( rand.intRangeAtMost(u8, 0, conf.maxMutRate) );
                const a = rand.float(f32);

                cons[ii].weight = a;
           }
                const a = rand.float(f32);
        //    const a: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, conf.maxMutRate) );
        //    const b = rand.boolean();
           inputs[i].thresold = a;

        }
    }
};

