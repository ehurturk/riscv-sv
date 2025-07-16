module regfile #(
    parameter WIDTH = 32
) (
    input logic clk,
    input logic write_enable,
    // 5 bits for read/write registers: RV32I has 32 registers
    input logic [4:0] r_reg1, 
    input logic [4:0] r_reg2,
    input logic [4:0] w_reg,

    // write data
    input logic [WIDTH-1:0] w_data,

    output logic [WIDTH-1:0] r_data1,
    output logic [WIDTH-1:0] r_data2
);

logic [WIDTH-1:0] regs [0:31];

// async read:
assign r_data1 = (r_reg1 != 0) ? regs[r_reg1] : {WIDTH{1'b0}};
assign r_data2 = (r_reg2 != 0) ? regs[r_reg2] : {WIDTH{1'b0}};

// Sync write
always_ff @( posedge clk ) 
    begin
        if (write_enable && (w_reg != 0)) 
        begin
            regs[w_reg] <= w_data;
        end
    end
    
endmodule
