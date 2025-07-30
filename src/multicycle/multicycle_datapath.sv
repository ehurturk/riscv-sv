// multicycle RISC-V RV32I datapath

`include "../definitions/defs.svh"
`include "../definitions/type_enums.svh"

module multicycle_datapath #(
    parameter WIDTH = 32
)(
    input logic clk,
    input logic reset,
    
    input logic CTL_IorD,
    input logic CTL_MemWrite,
    input logic CTL_MemRead,
    input logic CTL_IRWrite,
    input logic CTL_RegWrite,
    input logic [1:0] CTL_MemToReg,
    input logic [1:0] CTL_PCSrc,
    input logic CTL_PCWriteCond,
    input logic CTL_PCWrite,
    input logic [1:0] CTL_ALUSrcA,
    input logic [2:0] CTL_ALUSrcB,
    input aluop_t CTL_ALUOp,
    
    // mem interface
    output logic [WIDTH-1:0] mem_addr,
    output logic [WIDTH-1:0] mem_write_data,
    output logic [3:0] mem_byteen,
    output logic mem_write_enable,
    output logic mem_read_enable,
    input logic [WIDTH-1:0] mem_read_data,
    
	// to cu
    output logic [6:0] opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7,

    output logic zero,
    
	// to instr mem:
    output logic [WIDTH-1:0] pc_out,
    output logic [WIDTH-1:0] ir_out
);

    logic [WIDTH-1:0] PC, PC_next;
    logic [WIDTH-1:0] IR;
    logic [WIDTH-1:0] MDR;
    logic [WIDTH-1:0] A, B;
    logic [WIDTH-1:0] ALUOut;
    
    logic [WIDTH-1:0] alu_result;
    logic [WIDTH-1:0] alu_srcA, alu_srcB;
    logic [WIDTH-1:0] immediate;
    logic [WIDTH-1:0] reg_write_data;
    logic [WIDTH-1:0] reg_data1, reg_data2;
    logic pc_enable;
    logic branch_taken;
    alu_t alu_control;
    
    logic [4:0] rs1, rs2, rd;

	logic [WIDTH-1:0] dmem_data_out;

    assign opcode = IR[6:0];
    assign funct3 = IR[14:12];
    assign funct7 = IR[31:25];
    assign rd = IR[11:7];
    assign rs1 = IR[19:15];
    assign rs2 = IR[24:20];
    
    assign pc_out = PC;
    assign ir_out = IR;
    
    assign pc_enable = CTL_PCWrite | (CTL_PCWriteCond & branch_taken);
    
	// PC
    always_ff @(posedge clk) begin
        if (reset) begin
            PC <= `RESET_VECTOR;
        end 
		else if (pc_enable) begin
            PC <= PC_next;
        end
    end
    
	mux4 #(
	.WIDTH(WIDTH)
	) MUXPCSrc(
		.signal(CTL_PCSrc),
		.d0    (alu_result), // pc+4
		.d1    (ALUOut),     // pc+imm (JAL: PC += {imm, 1'b0})
		.d2    ({alu_result[31:1], 1'b0}),  // JALR: PC = R[rs1] + imm
		.d3    (`ZERO), 
		.out   (PC_next)
	);
    
	// IR
    always_ff @(posedge clk) begin
        if (reset) begin
            IR <= 32'h00000013; // NOP
        end else if (CTL_IRWrite) begin
            IR <= mem_read_data;
        end
    end
    
    // MDR
    always_ff @(posedge clk) begin
        if (reset) begin
            MDR <= `ZERO;
        end else if (mem_read_enable && !CTL_IorD) begin
            MDR <= MDR;
        end else begin
            MDR <= dmem_data_out;
        end
    end
    
    // A/B
    always_ff @(posedge clk) begin
        if (reset) begin
            A <= `ZERO;
            B <= `ZERO;
        end else begin
            A <= reg_data1;
            B <= reg_data2;
        end
    end
    
    // ALUOut
    always_ff @(posedge clk) begin
        if (reset) begin
            ALUOut <= `ZERO;
        end else begin
            ALUOut <= alu_result;
        end
    end
    
    regfile #(
        .WIDTH(WIDTH)
    ) rf (
        .clk(clk),
        .write_enable(CTL_RegWrite),
        .r_reg1(rs1),
        .r_reg2(rs2),
        .w_reg(rd),
        .w_data(reg_write_data),

        .r_data1(reg_data1),
        .r_data2(reg_data2)
    );

	mux4 #(.WIDTH(WIDTH)) MUXRegWrite (
		.signal(CTL_MemToReg), 
		.d0(ALUOut), 
		.d1(MDR), // for loads
		.d2(PC),  // for JALR
		.d3(ALUOut),

		.out(reg_write_data)
	);
    
    immgen #(
        .WIDTH(WIDTH)
    ) ig (
        .instruction(IR),
        .imm_out(immediate)
    );
    
	mux4 #(.WIDTH(WIDTH)) MUXALUSrcA (
		.signal(CTL_ALUSrcA),
		.d0(PC),
		.d1(A),
		.d2(`ZERO), // for auipc base
		.d3(A),

		.out(alu_srcA)
	);
    
	mux8 #(.WIDTH(WIDTH)) MUXALUSrcB (
		.signal(CTL_ALUSrcB),
		.d0(B),
		.d1(32'h4),
		.d2(immediate),
		.d3(immediate << 1),
		.d4(`ZERO),
		.d5(B),
		.d6(B),
		.d7(B),

		.out(alu_srcB)
	);
    
    alu_control alu_ctrl (
        .func3(funct3),
        .func7(funct7),
        .aluop(CTL_ALUOp),
        .aluctr(alu_control)
    );
    
    alu #(
        .WIDTH(WIDTH)
    ) alu_inst (
        .op(alu_control),
        .opA(alu_srcA),
        .opB(alu_srcB),
        .out(alu_result),
        .out_is_zero(zero)
    );
    
    branch_unit bu (
        .i_r1(A),
        .i_r2(B),
        .i_func3(funct3),
        .i_bren(CTL_PCWriteCond),
        .o_taken(branch_taken)
    );

	dmem_interface #(
		.WIDTH(WIDTH)
	) dmem_int (
		.clk         (clk),
		.mem_read    (CTL_MemRead),
		.mem_write   (CTL_MemWrite),
		.func3       (funct3),
		.address_in  (CTL_IorD ? ALUOut : PC),
		.data_in     (B),

		.bus_data_out(mem_read_data), // raw mem read from the mem bus
		.data_out    (dmem_data_out),

		.bus_addr    (mem_addr),
		.bus_data_in (mem_write_data),
		.bus_byteen  (mem_byteen),
		.bus_we      (mem_read_enable),
		.bus_re      (mem_write_enable)
	);

endmodule
