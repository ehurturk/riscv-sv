// Top level module for a multicycle datapath

`define WIDTH 32

module top (
    input logic clock,
    input logic reset,

	// debug outs
	output logic [`WIDTH-1:0] bus_data_in,
	output logic [`WIDTH-1:0] bus_data_out,
	output logic [`WIDTH-1:0] bus_addr_in,
	output logic [3:0] bus_byteen,
	output logic bus_mem_read,
	output logic bus_mem_write,

	output logic [`WIDTH-1:0] pc,
	output logic [`WIDTH-1:0] ir
);

/* verilator public_module */
riscv_mc_core core(
	.clk(clock),
	.reset(reset),

	.mem_read_data(bus_data_out),

	.pc_out(pc),
    .ir_out(ir),

    .mem_byteen(bus_byteen),
    .mem_write_en(bus_mem_write),
    .mem_read_en(bus_mem_read),

	.mem_addr(bus_addr_in),
	.mem_write_data(bus_data_in)	
);

/* verilator public_module */
memory_bus #(.WIDTH(`WIDTH)) memory_bus (
	.clk(clock),
	
    .mem_read(bus_mem_read),
    .mem_write(bus_mem_write),

    .addr_in(bus_addr_in),
    .data_in(bus_data_in),

    .byteen(bus_byteen),
	
	.mem_data_out(bus_data_out)
);

endmodule
