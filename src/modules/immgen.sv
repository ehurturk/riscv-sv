`include "defs.svh"

`define R_SIGN  3'b111
`define I_SIGN  3'b000
`define S_SIGN  3'b001
`define SB_SIGN 3'b010
`define U_SIGN  3'b011
`define UJ_SIGN 3'b100
`define SH_SIGN 3'b101
`define DF_SIGN 3'b110

/*
 * Information regarding immediate generation can be found
 * in section 2.4, Volume I of the RISC-V ISA Manual
 * (https://drive.google.com/file/d/1uviu1nH-tScFfgrovvFCrj7Omv8tFtkp/view)
 */


module immgen #(
    parameter WIDTH = 32
) (
    input logic [WIDTH-1:0] instruction,
    output logic [WIDTH-1:0] imm_out
);

logic [6:0] opc;
logic sign_bit;
logic [2:0] imm_sgnl;
logic [4:0] shamt;

assign opc = instruction[6:0];
assign shamt = instruction[24:20];
assign sign_bit = instruction[31];

always_comb begin
    imm_sgnl = `DF_SIGN;
    case (opc)
        `OPC_RTYPE: imm_sgnl = `R_SIGN;
        `OPC_ITYPE: begin
            imm_sgnl = `I_SIGN; // immediate arithmetics default to I_SIGN
            // however shifts (slli, srli, srai) shoulud be SH_SIGN
            if (instruction[14:12] == `INSTR_FUNC3_SRL_SRA || instruction[14:12] == `INSTR_FUNC3_SLL)
                imm_sgnl = `SH_SIGN;

        end
        `OPC_ITYPE_E, `OPC_ITYPE_J, `OPC_ITYPE_L: imm_sgnl = `I_SIGN;
        `OPC_SBTYPE: imm_sgnl = `SB_SIGN;
        `OPC_STYPE: imm_sgnl = `S_SIGN;
        `OPC_UJTYPE: imm_sgnl = `UJ_SIGN;
        `OPC_UTYPE_A, `OPC_UTYPE_L:  imm_sgnl = `U_SIGN;
        default: imm_sgnl = `DF_SIGN;
    endcase
end

// 32-bit extended immediate format
//   Bits:
// I  (000) : {{21{sign_bit}}, instruction[30:20]}
// S  (001) : {{21{sign_bit}}, instruction[30:25], instruction[11:7]}
// SB (010) : {{20{sign_bit}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0}
// U  (011) : {instruction[31:12], 12'b0}
// UJ (100) : {{12{sign_bit}}, instruction[19:12], instruction[20],instruction[30:21], 1'b0}
// SH (101) : {27'b0, shamt}
// R  (111) : {WIDTH{1'b0}}

mux8 #(.WIDTH(32)) mux(
    .signal(imm_sgnl),
    .d0({{21{sign_bit}}, instruction[30:20]}),                                           // 000
    .d1({{21{sign_bit}}, instruction[30:25], instruction[11:7]}),                        // 001
    .d2({{20{sign_bit}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0}),  // 010
    .d3({instruction[31:12], 12'b0}),                                                    // 011
    .d4({{12{sign_bit}}, instruction[19:12], instruction[20],instruction[30:21], 1'b0}), // 100
    .d5({27'b0, shamt}),                                                                 // 101
    .d6({WIDTH{1'bx}}),              /* default case - debug */                          // 110
    .d7({WIDTH{1'b0}}),                                                                  // 111
    .out(imm_out)
);


endmodule
