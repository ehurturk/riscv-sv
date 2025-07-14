`define ALU_OPSIZE 4

// FUNC3 bits
// R-type instructions
`define INSTR_FUNC3_ADD_SUB  3'b000 // ADD: func7[5] = 0, SUB: func7[5] = 1
`define INSTR_FUNC3_SLL  3'b001
`define INSTR_FUNC3_SLT  3'b010
`define INSTR_FUNC3_SLTU 3'b011
`define INSTR_FUNC3_XOR  3'b100
`define INSTR_FUNC3_SRL_SRA  3'b101 // SRL: func7[5] = 0, SRA: func7[5] = 1
`define INSTR_FUNC3_OR   3'b110
`define INSTR_FUNC3_AND  3'b111

// FUNC7 bits
// R-type instructions
`define INSTR_FUNC7_ADD 1'b0
`define INSTR_FUNC7_SUB 1'b1
`define INSTR_FUNC7_SRL 1'b0
`define INSTR_FUNC7_SRA 1'b1


// Opcode bits
`define OPC_RTYPE    7'b0110011  // r-type
`define OPC_ITYPE    7'b0010011  // i-type
`define OPC_ITYPE_L  7'b0000011  // loads (lb, lbu, lh, lhu, lw)
`define OPC_ITYPE_J  7'b1100111  // jalr
`define OPC_ITYPE_E  7'b1110011  // environment (ebreak ecall)
`define OPC_STYPE    7'b0100011  // stores
`define OPC_SBTYPE   7'b1100011  // branch
`define OPC_UTYPE_A  7'b0010111  // auipc
`define OPC_UTYPE_L  7'b0110111  // lui
`define OPC_UJTYPE   7'b1101111  // jal