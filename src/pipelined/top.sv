// Top level module for 5-stage pipelined RISC-V core

`define WIDTH 32

module top (
    input logic clk,
    input logic reset,

    // Debug outputs
    output logic [`WIDTH-1:0] o_bus_data_in,
    output logic [`WIDTH-1:0] o_bus_data_out,
    output logic [`WIDTH-1:0] o_bus_addr_in,
    output logic [3:0] o_bus_byteen,
    output logic o_bus_mem_read,
    output logic o_bus_mem_write,

    // pipeline stage pcs for debugging
    output logic [`WIDTH-1:0] o_pc_if,
    output logic [`WIDTH-1:0] o_pc_id,
    output logic [`WIDTH-1:0] o_pc_ex,
    output logic [`WIDTH-1:0] o_pc_mem,
    output logic [`WIDTH-1:0] o_pc_wb,
    
    // pipeline stage instructions for debugging
    output logic [`WIDTH-1:0] o_instruction_if,
    output logic [`WIDTH-1:0] o_instruction_id,
    output logic [`WIDTH-1:0] o_instruction_ex,
    output logic [`WIDTH-1:0] o_instruction_mem,
    output logic [`WIDTH-1:0] o_instruction_wb
);

    /* verilator public_module */
    riscv_pipelined_core core(
        .i_clk(clk),
        .i_reset(reset),

        .i_mem_read_data(o_bus_data_out),

        .o_mem_addr(o_bus_addr_in),
        .o_mem_write_data(o_bus_data_in),
        .o_mem_byteen(o_bus_byteen),
        .o_mem_write_en(o_bus_mem_write),
        .o_mem_read_en(o_bus_mem_read),
        
        // debugs
        .o_pc_if(o_pc_if),
        .o_pc_id(o_pc_id),
        .o_pc_ex(o_pc_ex),
        .o_pc_mem(o_pc_mem),
        .o_pc_wb(o_pc_wb),
        .o_instruction_if(o_instruction_if),
        .o_instruction_id(o_instruction_id),
        .o_instruction_ex(o_instruction_ex),
        .o_instruction_mem(o_instruction_mem),
        .o_instruction_wb(o_instruction_wb)
    );

    /* verilator public_module */
    memory_bus #(.WIDTH(`WIDTH)) memory_bus (
        .clk(clk),

        .mem_read(o_bus_mem_read),
        .mem_write(o_bus_mem_write),

        .addr_in(o_bus_addr_in),
        .data_in(o_bus_data_in),

        .byteen(o_bus_byteen),

        .mem_data_out(o_bus_data_out)
    );

endmodule
