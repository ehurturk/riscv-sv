

module riscv_mc_core #(
    parameter WIDTH = 32
) (
    input logic clk,
    input logic reset,

    input logic [WIDTH-1:0] mem_read_data,

    output logic [WIDTH-1:0] pc_out,
    output logic [WIDTH-1:0] ir_out,

    output logic [WIDTH-1:0] mem_addr,
    output logic [WIDTH-1:0] mem_write_data,
    output logic [3:0] mem_byteen,
    output logic mem_write_en,
    output logic mem_read_en
);

logic CTL_IorD;
logic CTL_MemWrite;
logic CTL_MemRead;
logic CTL_IRWrite;
logic CTL_RegWrite;
logic [1:0] CTL_MemToReg;
logic [1:0] CTL_PCSrc;
logic CTL_PCWriteCond;
logic CTL_PCWrite;
logic [1:0] CTL_ALUSrcA;
logic [2:0] CTL_ALUSrcB;
aluop_t CTL_ALUOp;

logic [6:0] instr_opc;

logic is_alu_zero; // unused


multicycle_datapath #(.WIDTH(WIDTH)) multicycle_datapath (
    .clk(clk),
    .reset(reset),

    .CTL_IorD(CTL_IorD),
    .CTL_MemWrite(CTL_MemWrite),
    .CTL_MemRead(CTL_MemRead),
    .CTL_IRWrite(CTL_IRWrite),
    .CTL_RegWrite(CTL_RegWrite),
    .CTL_MemToReg(CTL_MemToReg),
    .CTL_PCSrc(CTL_PCSrc),
    .CTL_PCWriteCond(CTL_PCWriteCond),
    .CTL_PCWrite(CTL_PCWrite),
    .CTL_ALUSrcA(CTL_ALUSrcA),
    .CTL_ALUSrcB(CTL_ALUSrcB),
    .CTL_ALUOp(CTL_ALUOp),

    .opcode(instr_opc),

    .zero(is_alu_zero),

    .pc_out(pc_out),
    .ir_out(ir_out),

    .mem_addr(mem_addr),
    .mem_write_data(mem_write_data),
    .mem_byteen(mem_byteen),
    .mem_write_enable(mem_write_en),
    .mem_read_enable(mem_read_en),
    .mem_read_data(mem_read_data)
);
    
mccontrol control_fsm (
    .clk(clk),
    .reset(reset),

    .instr_opc(instr_opc),

    .CTL_IorD(CTL_IorD),
    .CTL_MemWrite(CTL_MemWrite),
    .CTL_MemRead(CTL_MemRead),
    .CTL_IRWrite(CTL_IRWrite),
    .CTL_RegWrite(CTL_RegWrite),
    .CTL_MemToReg(CTL_MemToReg),
    .CTL_PCSrc(CTL_PCSrc),
    .CTL_PCWriteCond(CTL_PCWriteCond),
    .CTL_PCWrite(CTL_PCWrite),
    .CTL_ALUSrcA(CTL_ALUSrcA),
    .CTL_ALUSrcB(CTL_ALUSrcB),
    .CTL_ALUOp(CTL_ALUOp)
);  

endmodule