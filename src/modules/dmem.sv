`include "../definitions/defs.svh"

/*
 * RISC-V ISA Manual, Volume I, Section 2.6:
 *   "RV32I provides a 32-bit address space that is byte-addressed."
 */

module dmem #(
    parameter WIDTH = 32
) (
    input logic clk,

    input logic mem_read,
    input logic mem_write,

    input logic [WIDTH-1-2:0] addr_in,  // 30 bits (word aligned) coming from dmem bus
    input logic [  WIDTH-1:0] data_in,

    /*
     *    byteen   | load instr
     *    =====================
     *    0b0001   |    lb
     *    0b0011   |    lh
     *    0b1111   |    lw
     */
    input logic [3:0] byteen,

    output logic [WIDTH-1:0] data_out
);

  logic [WIDTH-1:0] mem[0:`DMEM_MEM_SIZE/4 - 1];

  assign data_out = mem[addr_in[9:0]];

  always_ff @(posedge clk) begin
    if (mem_write) begin
      if (byteen[0]) mem[addr_in[9:0]][0+:8] <= data_in[0+:8];
      if (byteen[1]) mem[addr_in[9:0]][8+:8] <= data_in[8+:8];
      if (byteen[2]) mem[addr_in[9:0]][16+:8] <= data_in[16+:8];
      if (byteen[3]) mem[addr_in[9:0]][24+:8] <= data_in[24+:8];
    end
  end

endmodule
