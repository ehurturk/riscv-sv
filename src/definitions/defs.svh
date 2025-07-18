`ifndef DEFS
`define DEFS

`define TEXT_MEM_SIZE 4'h1000
`define DMEM_MEM_SIZE 4'h1000
// TODO: write MMIO_MEM_SIZE as well

// Memory layout:
`define RESET_VECTOR 32'h00000000
`define TEXT_MEM_BEGIN `RESET_VECTOR
`define TEXT_MEM_END   `RESET_VECTOR + `TEXT_MEM_SIZE - 1
`define DMEM_MEM_BEGIN `TEXT_MEM_END + 1
`define DMEM_MEM_END   `DMEM_MEM_BEGIN + `DMEM_MEM_SIZE - 1
// TODO: write MMIO_MEM_BEGIN / MMIO_MEM_END as well

`define FOUR 32'h00000004
`define ZERO 32'b0

`define ALU_OPSIZE 4

// FUNC3 bits
`define INSTR_FUNC3_BITS_BEGIN 12
`define INSTR_FUNC3_BITS_END 14

// R-type instructions
`define INSTR_FUNC3_ADD_SUB 3'b000 // ADD: func7[5] = 0, SUB: func7[5] = 1
`define INSTR_FUNC3_SLL 3'b001
`define INSTR_FUNC3_SLT 3'b010
`define INSTR_FUNC3_SLTU 3'b011
`define INSTR_FUNC3_XOR 3'b100
`define INSTR_FUNC3_SRL_SRA 3'b101 // SRL: func7[5] = 0, SRA: func7[5] = 1
`define INSTR_FUNC3_OR 3'b110
`define INSTR_FUNC3_AND 3'b111

// B-type instructions
`define INSTR_FUNC3_BEQ 3'b000
`define INSTR_FUNC3_BNE 3'b001
`define INSTR_FUNC3_BLT 3'b100
`define INSTR_FUNC3_BGE 3'b101
`define INSTR_FUNC3_BLTU 3'b110
`define INSTR_FUNC3_BGEU 3'b111

// I-type Load/Store instructions
// last 2 bits describe:
//   00: B
//   01: H
//   11: W
// MSB describes:
//   0: Signed
//   1: Unsigned
`define INSTR_FUNC3_LB 3'b000
`define INSTR_FUNC3_LH 3'b001
`define INSTR_FUNC3_LW 3'b010
`define INSTR_FUNC3_LBU 3'b100
`define INSTR_FUNC3_LHU 3'b101
`define INSTR_FUNC3_SW 3'b000
`define INSTR_FUNC3_SH 3'b001
`define INSTR_FUNC3_SB 3'b010

// FUNC7 bits
// R-type instructions
`define INSTR_FUNC7_ADD 1'b0
`define INSTR_FUNC7_SUB 1'b1
`define INSTR_FUNC7_SRL 1'b0
`define INSTR_FUNC7_SRA 1'b1


// Opcode bits
`define OPC_RTYPE 7'b0110011  // r-type

`define OPC_ITYPE 7'b0010011  // i-type
`define OPC_ITYPE_L 7'b0000011  // loads (lb, lbu, lh, lhu, lw)
`define OPC_ITYPE_J 7'b1100111  // jalr
`define OPC_ITYPE_E 7'b1110011  // environment (ebreak ecall)

`define OPC_STYPE 7'b0100011  // stores

`define OPC_BTYPE 7'b1100011  // branch

`define OPC_UTYPE_A 7'b0010111  // auipc
`define OPC_UTYPE_L 7'b0110111  // lui

`define OPC_JTYPE 7'b1101111  // jal

`endif // DEFS
