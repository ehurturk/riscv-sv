

module riscv_mc_core #(
    parameter WIDTH = 32
) (
    input logic clk,
    input logic reset
);

multicycle_datapath #(.WIDTH(WIDTH)) multicycle_datapath (
    .clk(clk),
    .reset(reset)
);
    
endmodule