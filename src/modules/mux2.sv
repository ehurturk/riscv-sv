
// 32-bit (default) 2-input 1-bit signal input multiplexer
module mux2 #(
    parameter WIDTH = 32
) (
    input logic [WIDTH-1:0] d0,
    input logic [WIDTH-1:0] d1,
    input logic signal,
    output logic [WIDTH-1:0] out
);

  assign out = signal ? d1 : d0;

endmodule
