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
    input logic [31:0] rs1_data,  // Register source 1
    input logic [31:0] rs2_data,  // Register source 2
    input logic [2:0] func3,
    input logic branch_enable,

    output logic branch_taken
);

  always_comb begin
    if (!branch_enable) begin
      branch_taken = 1'b0;
    end else begin
      case (func3)
        `INSTR_FUNC3_BEQ:  branch_taken = (rs1_data == rs2_data);  // BEQ
        `INSTR_FUNC3_BNE:  branch_taken = (rs1_data != rs2_data);  // BNE
        `INSTR_FUNC3_BLT:  branch_taken = ($signed(rs1_data) < $signed(rs2_data));  // BLT
        `INSTR_FUNC3_BGE:  branch_taken = ($signed(rs1_data) >= $signed(rs2_data));  // BGE
        `INSTR_FUNC3_BLTU: branch_taken = (rs1_data < rs2_data);  // BLTU
        `INSTR_FUNC3_BGEU: branch_taken = (rs1_data >= rs2_data);  // BGEU
        default:           branch_taken = 1'b0;
      endcase
    end
  end

endmodule
