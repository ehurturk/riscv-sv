`include "defs.svh"

// ALU operations 
typedef enum logic [`ALU_OPSIZE-1:0] { 
    ALU_ADD  = `ALU_OPSIZE'b0000, // addition
    ALU_SUB  = `ALU_OPSIZE'b0001, // subtract
    ALU_AND  = `ALU_OPSIZE'b0010, // logical and
    ALU_OR   = `ALU_OPSIZE'b0011, // logical or
    ALU_XOR  = `ALU_OPSIZE'b0100, // logical xor
    ALU_SLL  = `ALU_OPSIZE'b0101, // shift left logical
    ALU_SRL  = `ALU_OPSIZE'b0110, // shift right logical
    ALU_SRA  = `ALU_OPSIZE'b0111, // shift right arithmetic
    ALU_SLT  = `ALU_OPSIZE'b1000, // set less than (signed) 
    ALU_SLTU = `ALU_OPSIZE'b1001  // set less than (unsigned)
} alu_op_t;
