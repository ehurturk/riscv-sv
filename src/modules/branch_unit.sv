`include "defs.svh"

/*
 * From RISC-V ISA Manual, Volume I, Section 2.5.2:
 *    The conditional branches were designed to include arithmetic
 *    comparison operations between two registers (as also done in PA-RISC,
 *    Xtensa, and MIPS R6), rather than use condition codes (x86, ARM, SPARC,
 *    PowerPC), or to only compare one register against zero (Alpha, MIPS),
 *    or two registers only for equality (MIPS).
 * Therefore branch unit is performed directly on register sources.
 */

module branch_unit (
    input logic [31:0] i_r1,  // register src 1
    input logic [31:0] i_r2,  // register src 2
    input logic [2:0] i_func3,
    input logic i_bren,

    output logic o_taken
);

  always_comb begin
    if (!i_bren) begin
      o_taken = 1'b0;
    end else begin
      case (i_func3)
        `INSTR_FUNC3_BEQ:  o_taken = (i_r1 == i_rs2);  // BEQ
        `INSTR_FUNC3_BNE:  o_taken = (i_r1 != i_rs2);  // BNE
        `INSTR_FUNC3_BLT:  o_taken = ($signed(i_r1) < $signed(i_rs2));  // BLT
        `INSTR_FUNC3_BGE:  o_taken = ($signed(i_r1) >= $signed(i_rs2));  // BGE
        `INSTR_FUNC3_BLTU: o_taken = (i_r1 < i_rs2);  // BLTU
        `INSTR_FUNC3_BGEU: o_taken = (i_r1 >= i_rs2);  // BGEU
        default:           o_taken = 1'b0;
      endcase
    end
  end

endmodule
