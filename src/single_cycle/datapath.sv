// datapath.sv - Single cycle RISC-V datapath (without control unit)

`include "defs.svh"

module datapath #(
	parameter WIDTH=32
)(
	input logic clk,
	
	// Control signals
	input logic CTL_RegWrite,
	input aluop_t CTL_AluOp,
	input logic CTL_AluSrc,
	input logic [1:0] CTL_PcSel,
	input logic CTL_BranchEnable,
	input logic CTL_MemRead,
	input logic CTL_MemWrite,
	input logic [2:0] CTL_MemToReg,

	input logic [WIDTH-1:0] bus_data_out,

	output logic take_branch,
	output logic [6:0] instruction_opc,
	
	output logic [WIDTH-1:0] bus_data_in,
	output logic bus_we,
	output logic bus_re,
	output logic [3:0] bus_byteen,
	output logic [WIDTH-1:0] bus_addr
);

	logic [WIDTH-1:0] next_pc;
	logic [WIDTH-1:0] current_pc;

	// reg file input/outputs
	logic [WIDTH-1:0] r_data1;
	logic [WIDTH-1:0] r_data2;
	logic [WIDTH-1:0] w_data;
	logic [4:0] r_reg1;
	logic [4:0] r_reg2;
	logic [4:0] w_reg;

	logic [WIDTH-1:0] dmem_data_out;


	logic [WIDTH-1:0] current_instruction;
	logic [WIDTH-1:0] immediate;

	logic [WIDTH-1:0] alu_src2;
	logic [WIDTH-1:0] alu_out;
	logic alu_out_zero;

	alu_t aluctr;

	// pcsrc mux
	// 00 -> PC = PC + 4
	// 01 -> PC = PC + IMM
	// 10 -> PC = R[rs1] + IMM
	// 11 -> 0
	mux4 #(
	.WIDTH(WIDTH)
	) MUXPCSrc(
		.signal(CTL_PcSel),
		.d0    (current_pc + FOUR),      // pc+4
		.d1    (current_pc + immediate), // pc+imm (JAL: PC += {imm, 1'b0})
		.d2    ({alu_out[31:1], 1'b0}),  // JALR: PC = R[rs1] + imm
		.d3    (`ZERO), 
		.out   (next_pc),
	);

	// pc register
	always_ff @(posedge clk) begin
		current_pc <= next_pc
	end


	imem_bus #(
		.WIDTH(WIDTH)	
	) imem_bus(
		.clk                 (clk),
		.pc                  (current_pc),
		.instruction_data_out(current_instruction)
	);

	mux8 #(
		.WIDTH(WIDTH)
	) MUXRegWB(
		.signal(CTL_MemToReg),
		.d0    (alu_out),                // R/I-type
		.d1    (dmem_data_out),          // I-type loads
		.d2    (current_pc + `FOUR),     // JAL/JALR
		.d3    (immediate),              // LUI
		.d4    (current_pc + immediate), // AUIPC
		.d5    (`ZERO),                  // ZERO
		.d6    (`ZERO),
		.d7    (`ZERO),
		.out   (w_data)
	);

	regfile #(
		.WIDTH(WIDTH)
	) regfile (
		.clk         (clk),
		.write_enable(CTL_RegWrite),
		.r_reg1      (r_reg1),
		.r_reg2      (r_reg2),
		.w_reg       (w_reg),
		.w_data      (w_data),
		.r_data1     (r_data1),
		.r_data2     (r_data2)
	);

	immgen #(
		.WIDTH(WIDTH)
	) immgen(
		.instruction(current_instruction),
		.imm_out    (immediate)
	);

	branch_unit branch_unit(
	    .i_r1   (r_data1),
	    .i_r2   (r_data2),
	    .i_func3(current_instruction[`INSTR_FUNC3_BITS_END:`INSTR_FUNC3_BITS_BEGIN]),
	    .i_bren (CTL_BranchEnable),
	    .o_taken(take_branch)
	);

	alu_control alu_ctl (
		.func3 (current_instruction[`INSTR_FUNC3_BITS_END:`INSTR_FUNC3_BITS_BEGIN]),
		.func7 (current_instruction[31:25]),
		.aluop (CTL_AluOp),
		.aluctr(aluctr)
	);

	mux2 #(
		.WIDTH(32)
	) MUXalusrc (
		.signal(CTL_AluSrc),
		.d0    (r_data2),
		.d1    (immediate),
		.out   (alu_src2)
	);

	alu #(
		.WIDTH(WIDTH)
	) alu (
		.op         (aluctr),
		.opA        (r_data1),
		.opB        (alu_src2),
		.out        (alu_out),
		.out_is_zero(alu_out_zero)
	);

	dmem_interface #(
		.WIDTH(WIDTH)
	) dmem_int (
		.clk         (clk),
		.mem_read    (CTL_MemRead),
		.mem_write   (CTL_MemWrite),
		.func3       (current_instruction[`INSTR_FUNC3_BITS_END:`INSTR_FUNC3_BITS_BEGIN]),
		.address_in  (alu_out),
		.data_in     (r_data2),

		// TODO
		.bus_data_out(bus_data_out),
		.data_out    (dmem_data_out),
		.bus_addr    (bus_addr),
		.bus_data_in (bus_data_in),
		.bus_byteen  (bus_byteen),
		.bus_we      (bus_we),
		.bus_re      (bus_re)
	);

endmodule : datapath
