pub const std = @import("std");

const conf = @import("bugsconfig.zig");
const nn = @import("bugsnuron.zig");

const bb: type = @import("bugsbug.zig");

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

    pub fn update(self: *Brain, fire: fn(self: *bb.Bug, id: usize)void, bself: *bb.Bug)void
    {


        var inps = &self.inputs.nurons;
        var hids = &self.hidden.nurons;
        var outs = &self.outputs.nurons;
        for(inps, 0..inps.len)|inp, i|
        {
            // _= inp;
            if(inp.neuronvalue>0.9)self.hidden.nurons[i].fire();
            inps[i].update();

        }
        for(hids, 0..hids.len)|hid, i|
        {
            hids[i].varsum = 0.0;

            for(hid.cons, 0..hid.cons.len)|con, c|
            {
                _=c;
                // search for conected nuron need rework with pinter


                    if(con.to < hids.len)
                    {
                        self.hidden.nurons[i].varsum += hids[con.to].neuronvalue * con.weight;
                    }

            }
            // when sum of all iputs reaches trezold fire nuron
            if( hids[i].varsum > hids[i].thresold )
            {
                print("hidden value is greater tha zero: {}\n", .{hids[i].varsum});
                self.hidden.nurons[i].fire();
            }
            self.hidden.nurons[i].update();

        }

        for(outs, 0..outs.len)|out, i|
        {
            outs[i].varsum = 0.0;

            for(out.cons, 0..out.cons.len)|con, c|
            {
                _=c;
                // search for conected nuron need rework with pinter


                    if(con.to < hids.len)
                    {
                        outs[i].varsum += hids[con.to].neuronvalue * con.weight;
                    }

            }
            // when sum of all iputs reaches trezold fire nuron
            if( outs[i].varsum > outs[i].thresold )
            {
                print("fire truster: {}\n", .{i});
                fire(bself, i);
            }


            outs[i].update();
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

                const rnd: f32 = @floatFromInt( rand.intRangeAtMost(u8, 0, 3) );

                _ = .{ a,  c, d };
                if(b)cons[ii].weight += rnd;
                if(!b)cons[ii].weight -= rnd;
           }
           const rand = std.crypto.random;
           const a: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, 3) );
           const b = rand.boolean();

           if(b)hidden[i].thresold += a;
           if(!b)hidden[i].thresold -= a;
           if(hidden[i].thresold < 0)hidden[i].thresold = 10.0;
        }

        var outputs = &self.outputs.nurons;
        for(outputs, 0..outputs.len)|nuron, i|
        {
            _= nuron;
           var cons = &outputs[i].cons;
           for(cons, 0..cons.len)|con,ii|
           {
                _=con;
                const rand = std.crypto.random;
                const a = rand.float(f32);
                const b = rand.boolean();
                const c = rand.int(u8);
                const d = rand.intRangeAtMost(u8, 0, 255);

                const rnd = a;

                _ = .{ a, c, d };

                if(b)cons[ii].weight += rnd;
                if(!b)cons[ii].weight -= rnd;
           }
           const rand = std.crypto.random;
           const a: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, 3) );
           const b = rand.boolean();
           if(b)outputs[i].thresold += a;
           if(!b)outputs[i].thresold -= a;
           if(outputs[i].thresold < 0)outputs[i].thresold = 10.0;
        }

        var inputs = &self.inputs.nurons;
        for(inputs, 0..inputs.len)|nuron, i|
        {
            _= nuron;
           var cons = &inputs[i].cons;
           for(cons, 0..cons.len)|con,ii|
           {
                _=con;
                const rand = std.crypto.random;
                const a = rand.float(f32);
                const b = rand.boolean();
                const c = rand.int(u8);
                const d = rand.intRangeAtMost(u8, 0, 255);

                const rnd = a;

                _ = .{ a, c, d };

                if(b)cons[ii].weight += rnd;
                if(!b)cons[ii].weight -= rnd;
           }
           const rand = std.crypto.random;
           const a: f32 =  @floatFromInt( rand.intRangeAtMost(u8, 0, 3) );
           const b = rand.boolean();
           if(b)inputs[i].thresold += a;
           if(!b)inputs[i].thresold -= a;
           if(inputs[i].thresold < 0)inputs[i].thresold = 10.0;
        }
    }


};

