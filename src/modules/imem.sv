`include "../definitions/defs.svh"
`include "../single_cycle/config.svh"

module imem #(
  parameter WIDTH = 32,
  localparam ADDR_W_ALIGNED_BITS = WIDTH - 2
) (
  input logic clk,
  input logic [ADDR_W_ALIGNED_BITS-1:0] address_in, // input address coming from the bus (word aligned)

  output logic [WIDTH-1:0] instruction_data_out
);

  logic [WIDTH-1:0] mem[0:(`TEXT_MEM_SIZE >> 2) - 1];

  initial begin

`ifdef USE_ROM
      $readmemh("mem/program.hex", mem);
`elsif USE_STATIC
    for (integer i = 0; i < ({16'b0,`TEXT_MEM_SIZE} >> 2); i++) begin // display first 32 mem items
        mem[i] = 32'h00000013;  // nop
    end
`endif

`ifdef SHOW_INITIAL_MEMORY
    $display("Loaded %0d instructions into IMEM", 14);
    for (integer i = 0; i < 32; i++) begin
        $display("mem[%0d] = %b <- 0x%08h", i, mem[i], mem[i]);
    end
`endif

  end

  assign instruction_data_out = mem[address_in[$clog2(`TEXT_MEM_SIZE >> 2)-1:0]];

endmodule
