`include "type_enums.sv"

module alu #(
    parameter WIDTH = 32
) (
    input alu_op_t op,
    input logic [WIDTH-1:0] opA,
    input logic [WIDTH-1:0] opB,


    output logic [WIDTH-1:0] out,
    output logic out_zero
);

always_comb begin
    unique case (op)
        ALU_ADD:  out = opA + opB;
        ALU_SUB:  out = opA - opB;
        ALU_AND:  out = opA & opB;
        ALU_OR:   out = opA | opB;
        ALU_XOR:  out = opA ^ opB;
        ALU_SLL:  out = opA << opB[4:0];
        ALU_SRL:  out = opA >> opB[4:0];
        ALU_SRA:  out = $signed(opA) >>> opB[4:0];
        ALU_SLT:  out = {{WIDTH-1{1'b0}}, $signed(opA) < $signed(opB)};
        ALU_SLTU: out = {{WIDTH-1{1'b0}}, opA < opB};
        default:  out = 32'hDEADBEEF;
    endcase
end

assign out_zero = 0;

endmodule
