`include "type_enums.sv"

`define FLAG_SIZE 4 // Flags: OF, SF, CF, ZF

module alu #(
    parameter WIDTH = 32
) (
    input alu_op_t op,
    input logic [WIDTH-1:0] opA,
    input logic [WIDTH-1:0] opB,

    output logic [WIDTH-1:0] out,
    output logic [`FLAG_SIZE-1:0] flags_out
);

logic carry_in_msb;
logic carry_out_msb;
logic [4:0] shamt; /* max 32 BITS shift amount for RV32I */
logic [WIDTH-2:0] unused_lower_bits;
logic [WIDTH-1:0] result;

always_comb begin
    carry_in_msb      = 0;
    carry_out_msb     = 0;
    result            = 0;
    shamt             = opB[4:0];
    unused_lower_bits = {WIDTH-1{1'b0}};
    out               = 0;

    unique case (op)
        ALU_ADD: begin
            {carry_in_msb, unused_lower_bits} = opA[WIDTH-2:0] + opB[WIDTH-2:0];
            {carry_out_msb, result}           = opA + opB;
            out = result;
        end

        ALU_SUB: begin
            {carry_in_msb, unused_lower_bits} = opA[WIDTH-2:0] - opB[WIDTH-2:0];
            {carry_out_msb, result}           = opA - opB;
            out = result;
        end

        ALU_AND:  out = opA & opB;
        ALU_OR:   out = opA | opB;
        ALU_XOR:  out = opA ^ opB;

        ALU_SLL: begin
            out = opA << shamt;
            carry_out_msb = (32'(shamt) < WIDTH) ? opA[WIDTH - shamt] : 1'b0;
        end

        ALU_SRL: begin
            out = opA >> shamt;
            carry_out_msb = (32'(shamt) < WIDTH) ? opA[shamt - 1] : 1'b0;
        end

        ALU_SRA: begin
            {carry_out_msb, out} = {opA[shamt - 1], $signed(opA) >>> shamt};
        end

        ALU_SLT:  out = {{WIDTH-1{1'b0}}, $signed(opA) < $signed(opB)};
        ALU_SLTU: out = {{WIDTH-1{1'b0}}, opA < opB};

        default:  out = {WIDTH{1'b1}}; // debug
    endcase
end

assign flags_out = {
    carry_in_msb ^ carry_out_msb, // Overflow flag
    out[WIDTH-1],                 // Sign flag
    carry_out_msb,                // Carry flag
    out == {WIDTH{1'b0}}          // Zero flag
};

endmodule
