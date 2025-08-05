// module: forwarding unit
// description: generates necessary forward signals that allow the EX stage to have forwarded data

module forwarding_unit (
    // EX stage
    // id/ex pipeline reg
    input logic [4:0] i_ex_rs1,
    input logic [4:0] i_ex_rs2,

    // MEM stage
    // ex/mem pipeline reg
    input logic [4:0] i_mem_rd,
    input logic i_mem_reg_write,

    // WB stage
    // mem/wb pipeline reg
    input logic [4:0] i_wb_rd,
    input logic i_wb_reg_write,

    // 00: no forwarding - use register file
    // 01: forward from MEM (EX/MEM alu_result)
    // 10: forward from WB (MEM/WB mem_data)
    output logic [1:0] o_forward_a,
    output logic [1:0] o_forward_b
);

    always_comb begin
        o_forward_a = 2'b00;
        o_forward_b = 2'b00;
        
        // if ex stage has data dependency to mem stage instruction:
        //     forward the ex_mem_alu_result to ex stage instruction
        if (i_mem_reg_write &&
            (i_mem_rd != 5'b0) &&
            (i_mem_rd == i_ex_rs1)) begin
            o_forward_a = 2'b01;
        end
        
        // if ex stage has data dependency to wb stage instruction:
        //     forward the mem_wb_mem_data to ex stage instruction 
        //     (don't wait for memory loaded data writeback to regfile)
        else if (i_wb_reg_write &&
                 (i_wb_rd != 5'b0) &&
                 (i_wb_rd == i_ex_rs1)) begin
            o_forward_a = 2'b10;
        end
        
        if (i_mem_reg_write &&
            (i_mem_rd != 5'b0) &&
            (i_mem_rd == i_ex_rs2)) begin
            o_forward_b = 2'b01;
        end
        
        else if (i_wb_reg_write &&
                 (i_wb_rd != 5'b0) &&
                 (i_wb_rd == i_ex_rs2)) begin
            o_forward_b = 2'b10;
        end
    end

endmodule