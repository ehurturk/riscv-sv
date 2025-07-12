// 32-bit (default) 3-input 2-bit signal input multiplexer
module mux3 #(
    parameter WIDTH = 32
) (
    input logic [WIDTH-1:0] d0,
    input logic [WIDTH-1:0] d1,
    input logic [WIDTH-1:0] d2,
    input logic [WIDTH-1:0] d3,
    input logic [1:0] signal,
    output logic [WIDTH-1:0] out
);

always_comb 
    begin
        case (signal)
            2'd0:    out = d0;  
            2'd1:    out = d1;  
            2'd2:    out = d2;  
            default: out = 'x;
        endcase
    end
    
endmodule
