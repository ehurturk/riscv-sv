// 32-bit (default) 8-input 3-bit signal input multiplexer
module mux8 #(
    parameter WIDTH = 32
) (
    input logic [WIDTH-1:0] d0,
    input logic [WIDTH-1:0] d1,
    input logic [WIDTH-1:0] d2,
    input logic [WIDTH-1:0] d3,
    input logic [WIDTH-1:0] d4,
    input logic [WIDTH-1:0] d5,
    input logic [WIDTH-1:0] d6,
    input logic [WIDTH-1:0] d7,
    input logic [2:0] signal,
    output logic [WIDTH-1:0] out
);

always_comb 
    begin
        case (signal)
            3'b000:  out = d0;  
            3'b001:  out = d1;  
            3'b010:  out = d2;  
            3'b011:  out = d3;  
            3'b100:  out = d4;  
            3'b101:  out = d5;
            3'b110:  out = d6;  
            3'b111:  out = d7;  
            default: out = {WIDTH{1'bx}};
        endcase
    end
    
endmodule
