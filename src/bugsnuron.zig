// the nuron will be to spearate file later
const conf = @import("bugsconfig.zig");
const print = @import("bugsshared.zig").print;
pub const Con = struct {to: usize, weight: f32};

pub const Nuron = struct
{
    id: usize,
    x: f32,
    y: f32,
    z: f32,
    cons: [conf.maxCons] Con = undefined,
    neuronvalue: f32 = 0.1,
    pub fn conToAll(self: *Nuron) void
    {
        for(0..self.cons.len)|i|
        {
            const con: Con = Con{.to = i, .weight = 0.5};
            self.cons[i] = con;
        }
    }
    pub fn update(self: *Nuron, allnurons: []Nuron) void
    {
        // _=allnurons;
        var varsum: f32= 1.0;

        //  axson fires when all conected inputs value * weight  pass treasold 0.5
        for (self.cons, 0..self.cons.len) |con, i|
        {
            // _=con;
            // _=i;
            if(allnurons.len > i)
            {
                // print("all nuron id, totalneurons, counter i: {} {} {} {}\n", .{allnurons[i].id, allnurons.len, i, allnurons[i].neuronvalue});
                varsum = varsum * con.weight * allnurons[con.to].neuronvalue   ;
            }

        }
        if(varsum >= 0.5)
        {
            self.neuronvalue = 1.0;
        }
        else
        {
            self.neuronvalue = 0.1;
        }
        // print("varsum: {}\n", .{self.neuronvalue});
    }
    pub fn fire(self: *Nuron) void
    {
        self.neuronvalue = 1.0;
        print("nuron fired {}\n", .{self.id});
    }
};

