// 5-stage pipelined RISC-V RV32I core

`include "../definitions/defs.svh"
`include "../definitions/type_enums.svh"

module riscv_pipelined_core #(
    parameter WIDTH = 32
) (
    input logic i_clk,
    input logic i_reset,

    // Instruction memory interface
    input logic [WIDTH-1:0] i_instruction,
    output logic [WIDTH-1:0] o_pc_if,

    // Data memory interface
    input logic [WIDTH-1:0] i_dmem_read_data,
    output logic [WIDTH-1:0] o_dmem_addr,
    output logic [WIDTH-1:0] o_dmem_write_data,
    output logic [3:0] o_dmem_byteen,
    output logic o_dmem_write_en,
    output logic o_dmem_read_en,

    // Pipeline debug outputs
    output logic [WIDTH-1:0] o_pc_id,
    output logic [WIDTH-1:0] o_pc_ex,
    output logic [WIDTH-1:0] o_pc_mem,
    output logic [WIDTH-1:0] o_pc_wb,
    output logic [WIDTH-1:0] o_instruction_if,
    output logic [WIDTH-1:0] o_instruction_id,
    output logic [WIDTH-1:0] o_instruction_ex,
    output logic [WIDTH-1:0] o_instruction_mem,
    output logic [WIDTH-1:0] o_instruction_wb
);

    logic [1:0] CTL_if_pc_sel;
    logic CTL_if_pc_write;
    logic CTL_id_reg_write;
    logic [1:0] CTL_id_reg_write_src;
    logic [1:0] CTL_ex_alu_src_a;
    logic [2:0] CTL_ex_alu_src_b;
    logic CTL_ex_branch_enable;
    aluop_t CTL_ex_alu_op;
    logic CTL_mem_read, CTL_mem_write;
    logic CTL_wb_reg_write;
    logic [2:0] CTL_wb_reg_write_src;
    
    logic [6:0] if_opcode, id_opcode, ex_opcode, mem_opcode, wb_opcode;
    
    logic branch_taken, jump_taken;
    
    logic hazard_stall, hazard_flush;

    hazard_detection_unit hdu (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_id_rs1(5'b0),       // TODO: connect actual rs1 from ID stage
        .i_id_rs2(5'b0),       // TODO: connect actual rs2 from ID stage
        .i_ex_rd(5'b0),        // TODO: connect actual rd from EX stage
        .i_mem_rd(5'b0),       // TODO: connect actual rd from MEM stage
        .i_ex_mem_read(CTL_mem_read),
        .i_branch_taken(branch_taken),
        .i_jump_taken(jump_taken),
        .o_stall(hazard_stall),
        .o_flush(hazard_flush)
    );

    pipelined_datapath #(
        .WIDTH(WIDTH)
    ) datapath (
        .i_clk(i_clk),
        .i_reset(i_reset),
        
        // Control inputs
        .i_CTL_if_pc_sel(CTL_if_pc_sel),
        .i_CTL_if_pc_write(CTL_if_pc_write),
        .i_CTL_id_reg_write(CTL_id_reg_write),
        .i_CTL_id_reg_write_src(CTL_id_reg_write_src),
        .i_CTL_ex_alu_src_a(CTL_ex_alu_src_a),
        .i_CTL_ex_alu_src_b(CTL_ex_alu_src_b),
        .i_CTL_ex_alu_op(CTL_ex_alu_op),
        .i_CTL_ex_branch_enable(CTL_ex_branch_enable),
        .i_CTL_mem_read(CTL_mem_read),
        .i_CTL_mem_write(CTL_mem_write),
        .i_CTL_wb_reg_write(CTL_wb_reg_write),
        .i_CTL_wb_reg_write_src(CTL_wb_reg_write_src),
        
        // Instruction memory interface
        .i_instruction(i_instruction),
        .o_pc_if(o_pc_if),

        // Data memory interface
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_write_data(o_dmem_write_data),
        .o_dmem_byteen(o_dmem_byteen),
        .o_dmem_write_enable(o_dmem_write_en),
        .o_dmem_read_enable(o_dmem_read_en),
        .i_dmem_read_data(i_dmem_read_data),
        
        // Control feedback
        .o_if_opcode(if_opcode),
        .o_id_opcode(id_opcode),
        .o_ex_opcode(ex_opcode),
        .o_mem_opcode(mem_opcode),
        .o_wb_opcode(wb_opcode),
        
        // Branch/jump feedback
        .o_branch_taken(branch_taken),
        .o_jump_taken(jump_taken),
        
        // Debug outputs (excluding o_pc_if which is already connected above)
        .o_pc_id(o_pc_id),
        .o_pc_ex(o_pc_ex),
        .o_pc_mem(o_pc_mem),
        .o_pc_wb(o_pc_wb),
        .o_instruction_if(o_instruction_if),
        .o_instruction_id(o_instruction_id),
        .o_instruction_ex(o_instruction_ex),
        .o_instruction_mem(o_instruction_mem),
        .o_instruction_wb(o_instruction_wb)
    );

    pipelined_control control (
        .i_clk(i_clk),
        .i_reset(i_reset),
        
        // Opcode inputs
        .i_if_opcode(if_opcode),
        .i_id_opcode(id_opcode),
        .i_ex_opcode(ex_opcode),
        .i_mem_opcode(mem_opcode),
        .i_wb_opcode(wb_opcode),
        
        .i_branch_taken(branch_taken),
        .i_jump_taken(jump_taken),
        
        .i_hazard_stall(hazard_stall),
        .i_hazard_flush(hazard_flush),
        
        .o_CTL_if_pc_sel(CTL_if_pc_sel),
        .o_CTL_if_pc_write(CTL_if_pc_write),
        .o_CTL_id_reg_write(CTL_id_reg_write),
        .o_CTL_id_reg_write_src(CTL_id_reg_write_src),
        .o_CTL_ex_alu_src_a(CTL_ex_alu_src_a),
        .o_CTL_ex_alu_src_b(CTL_ex_alu_src_b),
        .o_CTL_ex_alu_op(CTL_ex_alu_op),
        .o_CTL_ex_branch_enable(CTL_ex_branch_enable),
        .o_CTL_mem_read(CTL_mem_read),
        .o_CTL_mem_write(CTL_mem_write),
        .o_CTL_wb_reg_write(CTL_wb_reg_write),
        .o_CTL_wb_reg_write_src(CTL_wb_reg_write_src)
    );

endmodule
