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
            2'b000:  out = d0;  
            2'b001:  out = d1;  
            2'b010:  out = d2;  
            2'b011:  out = d3;  
            2'b100:  out = d4;  
            2'b101:  out = d5  
            2'b110:  out = d6;  
            2'b111:  out = d7;  
            default: out = {WIDTH{1'bx}};
        endcase
    end
    
endmodule
