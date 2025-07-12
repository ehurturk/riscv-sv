`include "defs.svh"

// ALU operations 
typedef enum logic [`ALU_OPSIZE-1:0] { 
    ALU_ADD  = `ALU_OPSIZE'b0000,
    ALU_SUB  = `ALU_OPSIZE'b0001,
    ALU_AND  = `ALU_OPSIZE'b0010,
    ALU_OR   = `ALU_OPSIZE'b0011,
    ALU_XOR  = `ALU_OPSIZE'b0100,
    ALU_SLL  = `ALU_OPSIZE'b0101,
    ALU_SRL  = `ALU_OPSIZE'b0110,
    ALU_SRA  = `ALU_OPSIZE'b0111,
    ALU_SLT  = `ALU_OPSIZE'b1000,
    ALU_SLTU = `ALU_OPSIZE'b1001
} alu_op_t;
