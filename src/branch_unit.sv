module branch_unit (
    input logic [3:0] alu_flags,
    input logic [2:0] func3,
    input logic branch_enable, // From CU
    
    output logic branch_taken
);

always_comb begin
    if (!branch_enable) begin
        branch_taken = 1'b0;
    end else begin
        case (func3)
            3'b000: branch_taken = alu_flags[0];                    // BEQ: ZF
            3'b001: branch_taken = !alu_flags[0];                   // BNE: !ZF
            3'b100: branch_taken = alu_flags[1] ^ alu_flags[3];     // BLT: SF XOR OF
            3'b101: branch_taken = !(alu_flags[1] ^ alu_flags[3]);  // BGE: !(SF XOR OF)
            3'b110: branch_taken = !alu_flags[2];                   // BLTU: !CF
            3'b111: branch_taken = alu_flags[2];                    // BGEU: CF
            default: branch_taken = 1'b0;
        endcase
    end
end

endmodule