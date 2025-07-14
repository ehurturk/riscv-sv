`define ALU_OPSIZE 4

// FUNC3 bits
// R-type instructions
`define INSTR_FUNC3_ADD 3'b000 // func7[30] = 0
`define INSTR_FUNC3_SUB 3'b000 // func7[30] = 1
`define INSTR_FUNC3_SLL 3'b001
`define INSTR_FUNC3_SLT 3'b010
`define INSTR_FUNC3_SLTU 3'b011
`define INSTR_FUNC3_XOR 3'b100
`define INSTR_FUNC3_SRL 3'b101 // func7[30] = 0
`define INSTR_FUNC3_SRA 3'b101 // func7[30] = 1
`define INSTR_FUNC3_OR 3'b110
`define INSTR_FUNC3_AND 3'b111

// FUNC7 bits
// R-type instructions
`define INSTR_FUNC7_ADD 1'b0
`define INSTR_FUNC7_SUB 1'b1
`define INSTR_FUNC7_SRL 1'b0
`define INSTR_FUNC7_SRA 1'b1


