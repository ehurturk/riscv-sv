// Unified memory (von Neumann model) bus

`include "../definitions/defs.svh"

module memory_bus #(
    parameter WIDTH = 32
) (
    input logic clk,

    // control signals
    input logic mem_read,
    input logic mem_write,

    input logic [WIDTH-1:0] addr_in,
    input logic [WIDTH-1:0] data_in,

    input logic [3:0] byteen,

    output logic [WIDTH-1:0] mem_data_out
);

logic [WIDTH-1:0] dmem_out, imem_out;

logic is_mem_data;
logic is_mem_instr;

assign is_mem_data = (addr_in >= `DMEM_MEM_BEGIN) && (addr_in <= `DMEM_MEM_END);
assign is_mem_instr = (addr_in <= `TEXT_MEM_END);

/* verilator public_module */
dmem #(
    .WIDTH(WIDTH)
) data_memory (
    .clk(clk),
    .mem_read(mem_read),
    .mem_write(mem_write && is_mem_data),
    .addr_in(addr_in[WIDTH-1:2]),
    .data_in(data_in),
    .byteen(byteen),

    .data_out(dmem_out)
);

/* verilator public_module */
imem #(
    .WIDTH(WIDTH)
) instruction_memory (
    .clk(clk),
    .address_in(addr_in[WIDTH-1:2]),

    .instruction_data_out(imem_out)
);

assign mem_data_out = mem_read && is_mem_instr ? imem_out : mem_read && is_mem_data ? dmem_out : 32'h0;

endmodule : memory_bus
