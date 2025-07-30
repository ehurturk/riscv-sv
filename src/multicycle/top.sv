// Top level module for a multicycle datapath

`define WIDTH 32

module top (
    input logic clock,
    input logic reset,

	output logic [`WIDTH-1:0] bus_data_in,
	output logic [`WIDTH-1:0] bus_data_out,
	output logic [`WIDTH-1:0] bus_addr_in,
	output logic [3:0] bus_byteen,
	output logic bus_mem_read,
	output logic bus_mem_write,

	output logic [`WIDTH-1:0] pc
);

riscv_mc_core core(
	.clk(clock),
	.reset(reset)
);

memory_bus #(.WIDTH(`WIDTH)) memory_bus (
	.clk(clock)
	
);

endmodule
