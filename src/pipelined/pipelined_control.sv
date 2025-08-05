
`include "../definitions/type_enums.svh"
`include "../definitions/defs.svh"

module pipelined_control (
    input logic i_clk,
    input logic i_reset,

    input logic [6:0] i_id_opcode,
    
    input logic i_branch_taken,
    input logic i_jump_taken,
    
    input logic i_hazard_stall,
    input logic i_hazard_flush,
    
    // IF
    output logic [1:0] o_CTL_if_pc_sel,
    output logic o_CTL_if_pc_write,
    
    // ID  
    output logic o_CTL_id_reg_write,
    output logic [1:0] o_CTL_id_reg_write_src,
    
    // EX
    output logic [1:0] o_CTL_ex_alu_src_a,
    output logic [2:0] o_CTL_ex_alu_src_b,
    output aluop_t o_CTL_ex_alu_op,
    output logic o_CTL_ex_branch_enable,
    
    // MEM
    output logic o_CTL_mem_read,
    output logic o_CTL_mem_write,
    
    // WB
    output logic o_CTL_wb_reg_write,
    output logic [2:0] o_CTL_wb_reg_write_src,
    
    // for HDU
    output logic o_CTL_ex_is_load,
    
    // for FWU  
    output logic o_CTL_mem_reg_write
);

    logic [1:0] if_pc_sel_int;
    logic if_pc_write_int;
    logic id_reg_write_int;
    logic [1:0] id_reg_write_src_int;
    logic [1:0] ex_alu_src_a_int;
    logic [2:0] ex_alu_src_b_int;
    logic ex_branch_enable_int;
    aluop_t ex_alu_op_int;
    logic mem_read_int, mem_write_int;
    logic wb_reg_write_int;
    logic [2:0] wb_reg_write_src_int;
    
    // pipeline ctl regs
    logic [1:0] id_ex_reg_write_src;
    logic [1:0] id_ex_alu_src_a;
    logic [2:0] id_ex_alu_src_b;
    logic id_ex_branch_enable;
    aluop_t id_ex_alu_op;
    logic id_ex_mem_read, id_ex_mem_write;
    logic id_ex_wb_reg_write;
    logic [2:0] id_ex_wb_reg_write_src;
    
    logic ex_mem_mem_read, ex_mem_mem_write;
    logic ex_mem_wb_reg_write;
    logic [2:0] ex_mem_wb_reg_write_src;
    
    logic mem_wb_reg_write;
    logic [2:0] mem_wb_reg_write_src;

    // IF STAGE CTL
    always_comb begin
        if_pc_sel_int = 2'b00;
        if_pc_write_int = 1'b1;
        
        if (i_branch_taken || i_jump_taken) begin
            // PCSrc = alu_result
            if_pc_sel_int = 2'b01;
        end
        
        // handle hazard stalls
        if (i_hazard_stall) begin
            if_pc_write_int = 1'b0; 
        end
    end

    // ID STAGE CTL     
    always_comb begin
        // Default values
        id_reg_write_int = 1'b0;
        id_reg_write_src_int = 2'b00;
        ex_alu_src_a_int = 2'b01;
        ex_alu_src_b_int = 3'b000;
        ex_alu_op_int = ALUOP_ADD;
        ex_branch_enable_int = 1'b0;
        mem_read_int = 1'b0;
        mem_write_int = 1'b0;
        wb_reg_write_int = 1'b0;
        wb_reg_write_src_int = 3'b000;
        
        case (i_id_opcode)
            `OPC_RTYPE: begin
                ex_alu_src_a_int = 2'b01;     // Register data
                ex_alu_src_b_int = 3'b000;    // Register data  
                ex_alu_op_int = ALUOP_RTYPE;
                wb_reg_write_int = 1'b1;
                wb_reg_write_src_int = 3'b000; // ALU result
            end
            
            `OPC_ITYPE: begin
                ex_alu_src_a_int = 2'b01;     // Register data
                ex_alu_src_b_int = 3'b010;    // Immediate
                ex_alu_op_int = ALUOP_ITYPE;
                wb_reg_write_int = 1'b1;
                wb_reg_write_src_int = 3'b000; // ALU result
            end
            
            `OPC_ITYPE_L: begin               // Load instructions
                ex_alu_src_a_int = 2'b01;     // Register data
                ex_alu_src_b_int = 3'b010;    // Immediate
                ex_alu_op_int = ALUOP_ADD;
                mem_read_int = 1'b1;
                wb_reg_write_int = 1'b1;
                wb_reg_write_src_int = 3'b001; // Memory data
            end
            
            `OPC_STYPE: begin                 // Store instructions
                ex_alu_src_a_int = 2'b01;     // Register data
                ex_alu_src_b_int = 3'b010;    // Immediate
                ex_alu_op_int = ALUOP_ADD;
                mem_write_int = 1'b1;
                wb_reg_write_int = 1'b0;       // No writeback
            end
            
            `OPC_BTYPE: begin                 // Branch instructions
                ex_alu_src_a_int = 2'b01;     // Register data
                ex_alu_src_b_int = 3'b000;    // Register data
                ex_alu_op_int = ALUOP_SUB;
                ex_branch_enable_int = 1'b1;
                wb_reg_write_int = 1'b0;       // No writeback
            end
            
            `OPC_JTYPE: begin                 // JAL instruction
                ex_alu_src_a_int = 2'b00;     // PC
                ex_alu_src_b_int = 3'b010;    // Immediate
                ex_alu_op_int = ALUOP_ADD;
                wb_reg_write_int = 1'b1;
                wb_reg_write_src_int = 3'b010; // PC+4
            end
            
            `OPC_ITYPE_J: begin               // JALR instruction
                ex_alu_src_a_int = 2'b01;     // Register data
                ex_alu_src_b_int = 3'b010;    // Immediate
                ex_alu_op_int = ALUOP_ADD;
                wb_reg_write_int = 1'b1;
                wb_reg_write_src_int = 3'b010; // PC+4
            end
            
            `OPC_UTYPE_L: begin               // LUI instruction
                ex_alu_src_a_int = 2'b10;     // Zero 
                ex_alu_src_b_int = 3'b010;    // Immediate
                ex_alu_op_int = ALUOP_ADD;
                wb_reg_write_int = 1'b1;
                wb_reg_write_src_int = 3'b011; // Immediate
            end
            
            `OPC_UTYPE_A: begin               // AUIPC instruction
                ex_alu_src_a_int = 2'b00;     // PC
                ex_alu_src_b_int = 3'b010;    // Immediate
                ex_alu_op_int = ALUOP_ADD;
                wb_reg_write_int = 1'b1;
                wb_reg_write_src_int = 3'b100; // PC+Immediate
            end
            
            default: begin
                // NOP or unsupported instruction
                ex_alu_op_int = ALUOP_ADD;
                wb_reg_write_int = 1'b0;
            end
        endcase
    end

    // ================================
    // PIPELINE CONTROL REGISTERS
    // ================================
    
    // ID/EX pipeline control register
    always_ff @(posedge i_clk) begin
        if (i_reset || i_hazard_flush) begin
            id_ex_alu_src_a <= 2'b01;
            id_ex_alu_src_b <= 3'b000;
            id_ex_alu_op <= ALUOP_ADD;
            id_ex_branch_enable <= 1'b0;
            id_ex_mem_read <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_wb_reg_write <= 1'b0;
            id_ex_wb_reg_write_src <= 3'b000;
        end else if (!i_hazard_stall) begin
            id_ex_alu_src_a <= ex_alu_src_a_int;
            id_ex_alu_src_b <= ex_alu_src_b_int;
            id_ex_alu_op <= ex_alu_op_int;
            id_ex_branch_enable <= ex_branch_enable_int;
            id_ex_mem_read <= mem_read_int;
            id_ex_mem_write <= mem_write_int;
            id_ex_wb_reg_write <= wb_reg_write_int;
            id_ex_wb_reg_write_src <= wb_reg_write_src_int;
        end
    end
    
    // EX/MEM pipeline control register
    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            ex_mem_mem_read <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_wb_reg_write <= 1'b0;
            ex_mem_wb_reg_write_src <= 3'b000;
        end else begin
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_wb_reg_write <= id_ex_wb_reg_write;
            ex_mem_wb_reg_write_src <= id_ex_wb_reg_write_src;
        end
    end
    
    // MEM/WB pipeline control register
    always_ff @(posedge i_clk) begin
        if (i_reset) begin
            mem_wb_reg_write <= 1'b0;
            mem_wb_reg_write_src <= 3'b000;
        end else begin
            mem_wb_reg_write <= ex_mem_wb_reg_write;
            mem_wb_reg_write_src <= ex_mem_wb_reg_write_src;
        end
    end
    
    // IF stage outputs
    assign o_CTL_if_pc_sel = if_pc_sel_int;
    assign o_CTL_if_pc_write = if_pc_write_int;
    
    // ID stage outputs (not used in current datapath design)
    assign o_CTL_id_reg_write = 1'b0;           // Handled in WB stage
    assign o_CTL_id_reg_write_src = 2'b00;
    
    // EX stage outputs
    assign o_CTL_ex_alu_src_a = id_ex_alu_src_a;
    assign o_CTL_ex_alu_src_b = id_ex_alu_src_b;
    assign o_CTL_ex_alu_op = id_ex_alu_op;
    assign o_CTL_ex_branch_enable = id_ex_branch_enable;
    
    // MEM stage outputs
    assign o_CTL_mem_read = ex_mem_mem_read;
    assign o_CTL_mem_write = ex_mem_mem_write;
    
    // WB stage outputs
    assign o_CTL_wb_reg_write = mem_wb_reg_write;
    assign o_CTL_wb_reg_write_src = mem_wb_reg_write_src;
    
    assign o_CTL_ex_is_load = id_ex_mem_read;
    assign o_CTL_mem_reg_write = ex_mem_wb_reg_write;

endmodule
