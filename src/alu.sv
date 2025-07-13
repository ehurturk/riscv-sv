`include "type_enums.sv"

/*
 * OF: Overflow flag  -> MSB in carry XOR MSB out carry
 * SF: Sign flag      -> MSB out == 1
 * CF: Carry flag     -> MSB out carry
 * ZF: Zero flag      -> out == 0
 */
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

logic carry_in_msb = 0;
logic carry_out_msb = 0;

logic [4:0] shamt = opB[4:0];

always_comb begin
    unique case (op)
        ALU_ADD:  begin 
            {carry_in_msb, lower_bits} = opA[WIDTH-2:0] + opB[WIDTH-2:0]; // add 0:30 bits (leaving out the MSB)
            {carry_out_msb, result} = opA[WIDTH-1:0] + opB[WIDTH-1:0];    // add 0:31 bits (including the MSB)
            out = result;
        end

        ALU_SUB:  begin 
            {carry_in_msb, lower_bits} = opA[WIDTH-2:0] - opB[WIDTH-2:0]; // subtract 0:30 bits (leaving out the MSB)
            {carry_out_msb, result} = opA[WIDTH-1:0] - opB[WIDTH-1:0];    // subtract 0:31 bits (including the MSB)
            out = result;
        end

        ALU_AND:  out = opA & opB;
        ALU_OR:   out = opA | opB;
        ALU_XOR:  out = opA ^ opB;

        // FIXME What if we shift by multiple bits???? Then I suppose we have to say
        //       opA[WIDTH-1-opB[4:0]]

        // use opB[4:0] since max 5-bit information (32 bits) can be shifted
        ALU_SLL:  begin 
            out = opA << shamt;
            if (shamt < WIDTH) begin
                carry_out_msb = opA[WIDTH-shamt];
            end 
            else begin
                carry_out_msb = 1'b0;
            end
        end

        // use opB[4:0] since max 5-bit information (32 bits) can be shifted
        ALU_SRL:  begin 
            out = opA >> shamt;
            if (shamt < WIDTH) begin
                carry_out_msb = opA[shamt-1];
            end 
            else begin
                carry_out_msb = 1'b0;
            end
        end

        ALU_SRA:  begin
            {carry_out_msb, out} = {opA[shamt-1], $signed(opA) >>> opB[4:0]}; 
        end

        ALU_SLT:  out = {{WIDTH-1{1'b0}}, $signed(opA) < $signed(opB)};
        ALU_SLTU: out = {{WIDTH-1{1'b0}}, opA < opB};

        default:  out = {WIDTH{8'hDEADBEEF}}; // debug
    endcase
end

assign flags_out = {
    carry_in_msb ^ carry_out_msb, // OF
    out[WIDTH-1],                 // SF
    carry_out_msb,                // CF
    out == {WIDTH{1'b0}}          // ZF
};

endmodule
