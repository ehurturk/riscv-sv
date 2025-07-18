/*
 * A note on this design:
 *   func3, func7, and aluop are supplied from the Control Unit,
 *   and the aluop is a 2-bit binary signal that decodes ALU operations:
 *      OP    | ALUOP | Notes
 *      =============================================================
 *      ADD   |  00   | Forced ALU add
 *      SUB   |  01   | Forced ALU sub (useful for branch)
 *      RTYPE |  10   | ALU Operations for R-TYPE (look func3+func7)
 *      ITYPE |  11   | ALU Operations for I-TYPE (look func3+func7)
 *
 * This covers the RV32I integer instructions, as:
 *   R-type instructions: set based on the ALUOP R-type
 *   I-type arithmetic instructions: set based on the ALUOP I-type
 *   I-type load instructions: will use ALUOP_ADD signal -> ALU_ADD
 *   I-type jump instructions (JALR): will use ALUOP_ADD signal -> ALU_ADD
 *   S-type store instructions: will use ALUOP_ADD signal -> ALU_ADD
 *   UJ-type instructions (JAL): will use ALUOP_ADD signal -> ALU_ADD
 *   U-type instructions:
 *        - AUIPC: ALUOP_ADD -> ALU_ADD (PC + immediate)
 *        - LUI: ALUOP_ADD, opA = 0, opB = immediate (or bypass ALU entirely)
 *   SB-type instructions (branch): will use ALUOP_SUB signal -> ALU_SUB
 *        - The ALU flags of the result will be used for different branch instructions:
 *          - BEQ:  SUB + Check ZF (if zero do branch)
 *          - BNE:  SUB + Check ZF (if not zero do branch)
 *          - BLT:  SUB + Check (SF XOR OF) (if rs1 < rs2 do branch)
 *          - BGE:  SUB + Check !(SF XOR OF) (if rs1 >= rs2 do branch)
 *          - BLTU: SUB + Check CF (if rs1 < rs2 unsigned do branch)
 *          - BGEU: SUB + Check CF (if rs1 >= rs2 unsigned do branch)
 *        - NOTE: This check will be done in a separate branch unit
 */

`include "../definitions/defs.svh"
`include "../definitions/type_enums.svh"

module alu_control (
    input logic [2:0] func3,  // instruction bits 14-12
    input logic [6:0] func7,  // instruction bits 31-25
    input aluop_t aluop,
  
    output alu_t aluctr
);

  alu_t func_rtype;
  alu_t func_itype;
  alu_t default_func;
  alu_t alt_func;

  always_comb begin
    case (aluop)
      ALUOP_ADD:   aluctr = ALU_ADD;     // force ALU_ADD for add
      // branch handling will be done in branch control unit
      ALUOP_SUB:   aluctr = ALU_SUB;     // force ALU_SUB for subs
      ALUOP_RTYPE: aluctr = func_rtype;  // R-type handling
      ALUOP_ITYPE: aluctr = func_itype;  // I-type handling
      default: aluctr = ALU_UNDEFINED;
    endcase
  end

  // R-type
  always_comb begin
    if (func7[5]) func_rtype = alt_func;
    else func_rtype = default_func;
  end

  // I-type
  always_comb begin
    if (func7[5] && func3 == `INSTR_FUNC3_SRL_SRA) func_itype = alt_func;
    else func_itype = default_func;
  end

  // R-type
  always_comb begin
    case (func3)
      `INSTR_FUNC3_ADD_SUB: default_func = ALU_ADD;
      `INSTR_FUNC3_SRL_SRA: default_func = ALU_SRL;
      `INSTR_FUNC3_SLL:     default_func = ALU_SLL;
      `INSTR_FUNC3_SLT:     default_func = ALU_SLT;
      `INSTR_FUNC3_SLTU:    default_func = ALU_SLTU;
      `INSTR_FUNC3_XOR:     default_func = ALU_XOR;
      `INSTR_FUNC3_OR:      default_func = ALU_OR;
      `INSTR_FUNC3_AND:     default_func = ALU_AND;
      default:              default_func = ALU_UNDEFINED;
    endcase
  end

  always_comb begin
    case (func3)
      `INSTR_FUNC3_ADD_SUB: alt_func = ALU_SUB;
      `INSTR_FUNC3_SRL_SRA: alt_func = ALU_SRA;
      default:              alt_func = ALU_UNDEFINED;
    endcase
  end

endmodule
