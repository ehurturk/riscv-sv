`include "defs.svh"


module dmem_bus #(
    parameter WIDTH = 32
) (
    input logic clk,

    input logic mem_read,
    input logic mem_write,

    input logic [WIDTH-1:0] addr_in, // 32 bits because coming from ALU
    input logic [WIDTH-1:0] data_in,

    /*
     *    byteen   | load instr
     *    =====================
     *    0b0001   |    lb
     *    0b0011   |    lh
     *    0b1111   |    lw 
     */
    input logic [3:0] byteen, // byte enable for supporting byte, halfword load/stores


    output logic [WIDTH-1:0] data_out
);

logic [WIDTH-1:0] read_data;

dmem #(
    .WIDTH(32)
) dmem (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .addr_in(addr_in[WIDTH-1:2]), // word-align the address
    .data_in(data_in),
    .byteen(byteen),
    .data_out(read_data)
);

assign data_out = mem_read ? read_data : `ZERO;

endmodule
