// 5-stage pipelined RISC-V RV32I datapath

`include "../definitions/defs.svh"
`include "../definitions/type_enums.svh"

module pipelined_datapath #(
    parameter WIDTH = 32
)(
    input logic i_clk,
    input logic i_reset,
    
    input logic [1:0] i_CTL_if_pc_sel,
    input logic i_CTL_if_pc_write,
    
    input logic i_CTL_id_reg_write,
    input logic [1:0] i_CTL_id_reg_write_src,
    
    input logic [1:0] i_CTL_ex_alu_src_a,
    input logic [2:0] i_CTL_ex_alu_src_b,
    input aluop_t i_CTL_ex_alu_op,
    input logic i_CTL_ex_branch_enable,
    
    input logic i_CTL_mem_read,
    input logic i_CTL_mem_write,
    
    input logic i_CTL_wb_reg_write,
    input logic [2:0] i_CTL_wb_reg_write_src,
    
    // Instruction memory interface
    input logic [WIDTH-1:0] i_instruction,
    output logic [WIDTH-1:0] o_pc_if,
    
    // Data memory interface
    output logic [WIDTH-1:0] o_dmem_addr,
    output logic [WIDTH-1:0] o_dmem_write_data,
    output logic [3:0] o_dmem_byteen,
    output logic o_dmem_write_enable,
    output logic o_dmem_read_enable,
    input logic [WIDTH-1:0] i_dmem_read_data,
    
    // to CU
    output logic [6:0] o_if_opcode,
    output logic [6:0] o_id_opcode,
    output logic [6:0] o_ex_opcode,
    output logic [6:0] o_mem_opcode,
    output logic [6:0] o_wb_opcode,
    
    output logic o_branch_taken,
    output logic o_jump_taken,
    
    // debug
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

    logic [WIDTH-1:0] ifid_pc, ifid_instruction;
    
    logic [WIDTH-1:0] idex_pc, idex_instruction;
    logic [WIDTH-1:0] idex_reg_data1, idex_reg_data2;
    logic [WIDTH-1:0] idex_immediate;
    logic [4:0] idex_rs1, idex_rs2, idex_rd;
    logic [2:0] idex_funct3;
    logic [6:0] idex_funct7;
    
    logic [WIDTH-1:0] exmem_pc, exmem_instruction;
    logic [WIDTH-1:0] exmem_alu_result;
    logic [WIDTH-1:0] exmem_reg_data2;
    logic [4:0] exmem_rd;
    logic exmem_zero_flag;
    logic [2:0] exmem_funct3;
    
    logic [WIDTH-1:0] memwb_pc, memwb_instruction;
    logic [WIDTH-1:0] memwb_alu_result;
    logic [WIDTH-1:0] memwb_mem_data;
    logic [4:0] memwb_rd;
    

    logic [WIDTH-1:0] pc_current, pc_next, pc_plus4;
    logic [WIDTH-1:0] reg_data1, reg_data2, reg_write_data;
    logic [WIDTH-1:0] immediate;
    logic [WIDTH-1:0] alu_srcA, alu_srcB, alu_result;
    logic alu_zero;
    logic branch_condition_met;
    alu_t alu_control;
    
    logic [4:0] rs1, rs2, rd;
    logic [2:0] funct3;
    logic [6:0] funct7, opcode;
    
    assign rs1 = ifid_instruction[19:15];
    assign rs2 = ifid_instruction[24:20];
    assign rd = ifid_instruction[11:7];
    assign funct3 = ifid_instruction[14:12];
    assign funct7 = ifid_instruction[31:25];
    assign opcode = ifid_instruction[6:0];
    
    assign o_pc_if = pc_current;
    assign o_pc_id = ifid_pc;
    assign o_pc_ex = idex_pc;
    assign o_pc_mem = exmem_pc;
    assign o_pc_wb = memwb_pc;
    assign o_instruction_if = i_instruction;
    assign o_instruction_id = ifid_instruction;
    assign o_instruction_ex = idex_instruction;
    assign o_instruction_mem = exmem_instruction;
    assign o_instruction_wb = memwb_instruction;
    
    assign o_if_opcode = i_instruction[6:0];
    assign o_id_opcode = ifid_instruction[6:0];
    assign o_ex_opcode = idex_instruction[6:0];
    assign o_mem_opcode = exmem_instruction[6:0];
    assign o_wb_opcode = memwb_instruction[6:0];
    
    assign o_branch_taken = branch_condition_met;
    assign o_jump_taken = (idex_instruction[6:0] == `OPC_JTYPE) || (idex_instruction[6:0] == `OPC_ITYPE_J);
    
    // ================================
    // IF PHASE
    // ================================
    
    assign pc_plus4 = pc_current + 32'd4;
    
    mux4 #(.WIDTH(WIDTH)) MUXPCSrc (
        .signal(i_CTL_if_pc_sel), 
        .d0(pc_plus4),
        .d1(alu_result),
        .d2({alu_result[31:1], 1'b0}), 
        .d3(`ZERO),
        .out(pc_next)
    );
    
    // PC
    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            pc_current <= `RESET_VECTOR;
        end else if (i_CTL_if_pc_write) begin
            pc_current <= pc_next;
        end
    end
    
    // IF/ID pipeline register
    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            ifid_pc <= `ZERO;
            ifid_instruction <= 32'h00000013; // nop
        end else begin
            ifid_pc <= pc_current;
            ifid_instruction <= i_instruction; // instruction from imem_bus
        end
    end
    
    // ================================
    // ID PHASE
    // ================================
    
    regfile #(
        .WIDTH(WIDTH)
    ) rf (
        .clk(i_clk),
        .write_enable(i_CTL_wb_reg_write),
        .r_reg1(rs1),
        .r_reg2(rs2),
        .w_reg(memwb_rd),
        .w_data(reg_write_data),
        .r_data1(reg_data1),
        .r_data2(reg_data2)
    );
    
    immgen #(
        .WIDTH(WIDTH)
    ) ig (
        .instruction(ifid_instruction),
        .imm_out(immediate)
    );
    
    
    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            idex_pc <= `ZERO;
            idex_instruction <= 32'h00000013; // NOP
            idex_reg_data1 <= `ZERO;
            idex_reg_data2 <= `ZERO;
            idex_immediate <= `ZERO;
            idex_rs1 <= 5'b0;
            idex_rs2 <= 5'b0;
            idex_rd <= 5'b0;
            idex_funct3 <= 3'b0;
            idex_funct7 <= 7'b0;
        end else begin
            idex_pc <= ifid_pc;
            idex_instruction <= ifid_instruction;
            idex_reg_data1 <= reg_data1;
            idex_reg_data2 <= reg_data2;
            idex_immediate <= immediate;
            idex_rs1 <= rs1;
            idex_rs2 <= rs2;
            idex_rd <= rd;
            idex_funct3 <= funct3;
            idex_funct7 <= funct7;
        end
    end
    
    // ================================
    // EX PHASE
    // ================================
    
    mux4 #(.WIDTH(WIDTH)) MUXALUSrcA (
        .signal(i_CTL_ex_alu_src_a),
        .d0(idex_pc),
        .d1(idex_reg_data1),
        .d2(`ZERO),
        .d3(idex_reg_data1),
        .out(alu_srcA)
    );
    
    mux8 #(.WIDTH(WIDTH)) MUXALUSrcB (
        .signal(i_CTL_ex_alu_src_b),
        .d0(idex_reg_data2),
        .d1(32'h4),
        .d2(idex_immediate),
        .d3(idex_immediate << 1),
        .d4(`ZERO),
        .d5(idex_reg_data2),
        .d6(idex_reg_data2),
        .d7(idex_reg_data2),
        .out(alu_srcB)
    );
    
    alu_control alu_ctrl (
        .func3(idex_funct3),
        .func7(idex_funct7),
        .aluop(i_CTL_ex_alu_op),
        .aluctr(alu_control)
    );
    
    alu #(
        .WIDTH(WIDTH)
    ) alu_inst (
        .op(alu_control),
        .opA(alu_srcA),
        .opB(alu_srcB),
        .out(alu_result),
        .out_is_zero(alu_zero)
    );
    
    branch_unit bu (
        .i_r1(idex_reg_data1),
        .i_r2(idex_reg_data2),
        .i_func3(idex_funct3),
        .i_bren(i_CTL_ex_branch_enable),
        .o_taken(branch_condition_met)
    );
    
    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            exmem_pc <= `ZERO;
            exmem_instruction <= 32'h00000013; // NOP
            exmem_alu_result <= `ZERO;
            exmem_reg_data2 <= `ZERO;
            exmem_rd <= 5'b0;
            exmem_zero_flag <= 1'b0;
            exmem_funct3 <= 3'b0;
        end else begin
            exmem_pc <= idex_pc;
            exmem_instruction <= idex_instruction;
            exmem_alu_result <= alu_result;
            exmem_reg_data2 <= idex_reg_data2;
            exmem_rd <= idex_rd;
            exmem_zero_flag <= alu_zero;
            exmem_funct3 <= idex_funct3;
        end
    end
    
    // ================================
    // MEM PHASE
    // ================================
    
    // Data memory interface only
    logic [WIDTH-1:0] dmem_data_out;
    
    dmem_interface #(
        .WIDTH(WIDTH)
    ) dmem_int (
        .clk(i_clk),
        .mem_read(i_CTL_mem_read),
        .mem_write(i_CTL_mem_write),
        .func3(exmem_funct3),
        .address_in(exmem_alu_result),
        .data_in(exmem_reg_data2),
        .bus_data_out(i_dmem_read_data),
        .data_out(dmem_data_out),
        .bus_addr(o_dmem_addr),
        .bus_data_in(o_dmem_write_data),
        .bus_byteen(o_dmem_byteen),
        .bus_we(o_dmem_write_enable),
        .bus_re(o_dmem_read_enable)
    );
    
    
    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            memwb_pc <= `ZERO;
            memwb_instruction <= 32'h00000013; // NOP
            memwb_alu_result <= `ZERO;
            memwb_mem_data <= `ZERO;
            memwb_rd <= 5'b0;
        end else begin
            memwb_pc <= exmem_pc;
            memwb_instruction <= exmem_instruction;
            memwb_alu_result <= exmem_alu_result;
            memwb_mem_data <= dmem_data_out; // processed load data from dmem_interface
            memwb_rd <= exmem_rd;
        end
    end
    
    // ================================
    // WB PHASE
    // ================================
    
    logic [WIDTH-1:0] pc_plus4_wb, lui_immediate, auipc_result;
    
    assign pc_plus4_wb = memwb_pc + 32'd4;
    assign lui_immediate = {memwb_instruction[31:12], 12'b0};
    assign auipc_result = memwb_pc + {memwb_instruction[31:12], 12'b0};
    
    mux8 #(.WIDTH(WIDTH)) MUXRegWrite (
        .signal(i_CTL_wb_reg_write_src),
        .d0(memwb_alu_result),
        .d1(memwb_mem_data),
        .d2(pc_plus4_wb),         // for jal/jalr
        .d3(lui_immediate),
        .d4(auipc_result),        // PC+Imm for auipc
        .d5(memwb_alu_result),
        .d6(memwb_alu_result),
        .d7(memwb_alu_result),
        .out(reg_write_data)
    );

endmodule
