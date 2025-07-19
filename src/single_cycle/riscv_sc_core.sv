// module riscv single cycle core:
// 	datapath + control (without data/instruction memory buses)
`include "../definitions/type_enums.svh"

module riscv_sc_core #(
	parameter WIDTH=32
) (
	input logic clk,    // Clock
	input logic reset,


	input logic [WIDTH-1:0] instruction,

	// data but outputs:
	input logic [WIDTH-1:0] bus_data_out,

	// data bus inputs:
	output logic bus_mem_read,  // from CU
	output logic bus_mem_write, // from CU
	output logic [WIDTH-1:0] bus_addr_in,
    output logic [WIDTH-1:0] bus_data_in,
    output logic [3:0] bus_byteen,

	output logic [WIDTH-1:0] pc
);
	logic take_branch;
	logic [6:0] instruction_opc;

	aluop_t CTL_AluOp;
	logic [1:0] CTL_PcSel;
	logic CTL_AluSrc;
	logic CTL_MemRead;
	logic CTL_MemWrite;
	logic CTL_RegWrite;
	logic CTL_BranchEnable;
	logic [2:0] CTL_MemToReg;

	/* verilator public_module */
	datapath #(
		.WIDTH(WIDTH)
	) dp (
		.clk                (clk),
		.reset              (reset),

		.current_instruction(instruction),

		.CTL_AluOp          (CTL_AluOp),
		.CTL_PcSel          (CTL_PcSel),
		.CTL_AluSrc         (CTL_AluSrc),
		.CTL_MemRead        (CTL_MemRead),
		.CTL_MemToReg       (CTL_MemToReg),
		.CTL_MemWrite       (CTL_MemWrite),
		.CTL_RegWrite       (CTL_RegWrite),
		.CTL_BranchEnable   (CTL_BranchEnable),

		.take_branch        (take_branch),
		.instruction_opc    (instruction_opc),

		.bus_data_out       (bus_data_out),
		.bus_byteen         (bus_byteen),
		.bus_data_in        (bus_data_in),
		.bus_re             (bus_mem_read),
		.bus_we             (bus_mem_write),
		.bus_addr           (bus_addr_in),

		.pc                 (pc)
	);

	// control unit
	sccontrol cp (
		.take_branch     (take_branch),
		.inst_opc        (instruction_opc),

		.CTL_RegWrite    (CTL_RegWrite),
		.CTL_AluOp       (CTL_AluOp),
		.CTL_AluSrc      (CTL_AluSrc),
		.CTL_PcSel       (CTL_PcSel),
		.CTL_BranchEnable(CTL_BranchEnable),
		.CTL_MemRead     (CTL_MemRead),
		.CTL_MemWrite    (CTL_MemWrite),
		.CTL_MemToReg    (CTL_MemToReg)
	);

endmodule : riscv_sc_core
