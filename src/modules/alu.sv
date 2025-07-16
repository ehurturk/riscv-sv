`include "type_enums.sv"

module alu #(
    parameter WIDTH = 32
) (
    input alu_t op,
    input logic [WIDTH-1:0] opA,
    input logic [WIDTH-1:0] opB,
    output logic [WIDTH-1:0] out,
    output logic out_is_zero
);

always_comb begin
    if (out == 0)
        out_is_zero = 1'b1;
    else
        out_is_zero = 1'b0;
end

always_comb begin
    case (op)
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
        default:  out = {WIDTH{1'b0}};
    endcase
end

endmodule
