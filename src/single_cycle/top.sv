`define WIDTH 32

module top (
	input logic clk,    // Clock
	input logic reset,

	output logic [`WIDTH-1:0] bus_data_in,
	output logic [`WIDTH-1:0] bus_data_out,
	output logic [`WIDTH-1:0] bus_addr_in,
	output logic [3:0] bus_byteen,
	output logic bus_mem_read,
	output logic bus_mem_write,

	output logic [`WIDTH-1:0] pc
);

	logic [`WIDTH-1:0] instruction;

	/* verilator public_module */
	riscv_sc_core #(
		.WIDTH(`WIDTH)
	) core(
		.clk          (clk),
		.reset(reset),
		.pc           (pc),
		.instruction  (instruction),

		// bus data output (to read from data bus)
		.bus_data_out (bus_data_out),

		// bus inputs (to set)
		.bus_data_in  (bus_data_in),
		.bus_byteen   (bus_byteen),
		.bus_addr_in  (bus_addr_in),
		.bus_mem_read (bus_mem_read),
		.bus_mem_write(bus_mem_write)
	);

	/* verilator public_module */
	dmem_bus #(
		.WIDTH(`WIDTH)
	) dbus(
		.clk      (clk),

		// to read (from core)
		.data_in  (bus_data_in),
		.mem_read (bus_mem_read),
		.mem_write(bus_mem_write),
		.addr_in  (bus_addr_in),
		.byteen   (bus_byteen),

		// to set
		.data_out (bus_data_out)
	);

	imem_bus #(
		.WIDTH(`WIDTH)
	) ibus(
		.clk                 (clk),
		// to read (from core)
		.pc                  (pc),
		// to set
		.instruction_data_out(instruction)
	);

endmodule : top
