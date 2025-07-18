
module dmem_interface #(
    parameter WIDTH = 32
) (
    input logic clk,

    input logic mem_read,
    input logic mem_write,

    input logic [2:0] func3,  // for data format (h, b, w)
    input logic [WIDTH-1:0] address_in,
    input logic [WIDTH-1:0] data_in,

    input logic [WIDTH-1:0] bus_data_out,  // data from bus

    output logic [WIDTH-1:0] data_out,
    output logic [WIDTH-1:0] bus_addr,  // addr that goes to bus
    output logic [WIDTH-1:0] bus_data_in,  // write data that goes to bus
    output logic [3:0] bus_byteen,  // byteen that goes to bus
    output logic bus_we,
    output logic bus_re
);

  assign bus_addr = address_in;
  assign bus_we = mem_write;
  assign bus_re = mem_read;

  /*
 * Shift by address bit 2 LSB bits to set up correct
 * masking bits to set the correct memory position
 * with the correct shifted data in.
 * For example:
 *   Instruction: sb x1 37(x0) // PRE: x1 = 0xAC
 * So, data in is: 0x0000000AC
 * Address is 0b100101 -> addr_in[1:0] = 01,
 *  so shifted data in is: 0x0000AC00 (information is
 *  in byte position 1).
 *
 * The byte enable masking bits should therefore be
 * generated as:
 *   bus_byteen = 4'b0001 << 1 = 4'b0010 (indicating
 *   data is in byte position 1).
 *
 * The memory would look like (in *little endian*):
 *  Address: 36   37   38   39
 *          [??] [AC] [??] [??]
 *           ^    ^    ^    ^
 *  Enable:  0    1    0    0
 */
  assign bus_data_in = data_in << (8 * address_in[1:0]);

  logic [WIDTH-1:0] sz_ext;
  logic [WIDTH-1:0] ld_align_fix;

  assign data_out = sz_ext;

  always_comb begin
    bus_byteen = 4'b0000;
    case (func3[1:0])
      2'b00:   bus_byteen = 4'b0001 << address_in[1:0];  // b
      2'b01:   bus_byteen = 4'b0011 << address_in[1:0];  // h
      2'b10:   bus_byteen = 4'b1111;  // w
      default: bus_byteen = 4'b0000;
    endcase
  end

  always_comb begin
    ld_align_fix = bus_data_out >> (8 * address_in[1:0]);
  end

  always_comb begin
    case (func3[1:0])
      2'b00:   sz_ext = {{24{~func3[2] & ld_align_fix[7]}}, ld_align_fix[7:0]};  // [l/s]b
      2'b01:   sz_ext = {{16{~func3[2] & ld_align_fix[15]}}, ld_align_fix[15:0]};  // [l/s]h
      2'b10:   sz_ext = ld_align_fix[31:0];  // [l/s]w
      default: sz_ext = {WIDTH{1'bx}};
    endcase
  end

endmodule
