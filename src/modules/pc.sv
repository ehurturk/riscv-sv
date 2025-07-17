// module: program counter

`include "defs.svh"

// 4096 byte memory - 12 address bit
module pc #(
    parameter WIDTH = 32
) (
    input logic clk,
    input logic resest,
    input logic stall,
    input logic [31:0] pc_in,
    output logic [31:0] pc_out
);

  always_ff @(posedge clk) begin
    if (reset) pc_out <= 32'b0;
    else pc_out <= pc_in;
  end

endmodule
