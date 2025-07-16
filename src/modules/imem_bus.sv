module imem_bus #(
    parameter WIDTH = 32
) (
    input logic clk,
    input logic [WIDTH-1:0] pc, // input address coming from PC

    output logic [WIDTH-1:0] instruction_data_out 
);

imem #(
    .WIDTH(WIDTH)
) instruction_mem (
    .clk(clk),
    .address_in(pc[WIDTH-1:2]), // word align
    .instruction_data_out(instruction_data_out) // propagate
);

endmodule
