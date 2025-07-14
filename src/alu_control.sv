`include "type_enums.sv"

module alu_control (
    input logic [2:0] func3, // instruction bits 14-12
    input logic [6:0] func7, // instruction bits 31-25
    input aluop_t aluop,

    output alu_t aluctr 
);

always_comb begin
    case (aluop)
        ALUOP_ADD: aluctr = ALU_ADD;
        ALUOP_SUB: aluctr = ALU_SUB;
        
        ALUOP_RTYPE: begin
            case (func3)
                INSTR_FUNC3_ADD: begin              // ADD vs SUB
                    if (func7[5])  
                        aluctr = ALU_SUB;           // SUB instruction
                    else
                        aluctr = ALU_ADD;           // ADD instruction
                end
                INSTR_FUNC3_SLL: aluctr = ALU_SLL;
                INSTR_FUNC3_SLT: aluctr = ALU_SLT;
                INSTR_FUNC3_SLTU: aluctr = ALU_SLTU;
                INSTR_FUNC3_XOR: aluctr = ALU_XOR;
                INSTR_FUNC3_SRL: begin              // SRL vs SRA
                    if (func7[5]) 
                        aluctr = ALU_SRA;
                    else    
                        aluctr = ALU_SRL;
                end
                INSTR_FUNC3_OR: aluctr = ALU_OR;
                INSTR_FUNC3_AND: aluctr = ALU_AND;
                default: aluctr = 4'bx;
            endcase
        end
        
        ALUOP_ITYPE: begin
            case (func3)
                INSTR_FUNC3_ADD: aluctr = ALU_ADD;    // ADDI (no SUBI)
                INSTR_FUNC3_SLL: aluctr = ALU_SLL;    // SLLI
                INSTR_FUNC3_SLT: aluctr = ALU_SLT;    // SLTI
                INSTR_FUNC3_SLTU: aluctr = ALU_SLTU;  // SLTIU
                INSTR_FUNC3_XOR: aluctr = ALU_XOR;    // XORI
                INSTR_FUNC3_SRL: begin                // SRLI vs SRAI
                    if (func7[5]) 
                        aluctr = ALU_SRA;             // SRAI
                    else    
                        aluctr = ALU_SRL;             // SRLI
                end
                INSTR_FUNC3_OR: aluctr = ALU_OR;      // ORI
                INSTR_FUNC3_AND: aluctr = ALU_AND;    // ANDI
                default: aluctr = 4'bx;
            endcase
        end
        
        default: aluctr = 4'bx; 
    endcase
end
    
endmodule
