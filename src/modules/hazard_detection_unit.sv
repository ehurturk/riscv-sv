// module: hazard detection unit
// description: generates hazard signals (stall | flush) based on data dependencies

module hazard_detection_unit (
    // current instruction (ID stage)
    input logic [4:0] i_id_rs1, 
    input logic [4:0] i_id_rs2,

    // EX stage instruction
    input logic [4:0] i_ex_rd,
    input logic i_ex_is_load,
    
    // control hazards
    input logic i_branch_taken,
    input logic i_jump_taken,
    
    output logic o_stall,
    output logic o_flush
);    
    always_comb begin
        o_stall = 1'b0;
        o_flush = 1'b0;

        // control hazards 
        // flush when EX stage resolves the target address
        //   - branch_taken is resolved at the EX stage
        if (i_branch_taken || i_jump_taken) begin
            o_flush = 1'b1;
        end
        
        // pipeline interlock: load-use hazards
        else if (i_ex_is_load && 
            ((i_ex_rd == i_id_rs1) || (i_ex_rd == i_id_rs2)) &&
            (i_ex_rd != 5'b0)) begin
            o_stall = 1'b1;
        end
    end

endmodule
