`include "defs.svh"

module imem #(
    parameter WIDTH = 32,
    localparam ADDR_W_ALIGNED_BITS = WIDTH - 2
) (
    input logic clk,
    input logic [ADDR_W_ALIGNED_BITS:0] address_in, // input address coming from the bus (word aligned)

    output logic [WIDTH-1:0] instruction_data_out
);

  logic [WIDTH-1:0] mem[0:TEXT_MEM_SIZE/4 - 1];

  assign instruction_data_out = mem[address_in];

endmodule
