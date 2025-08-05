`define WIDTH 32

module top (
    input logic clk,
    input logic reset,

    output logic [`WIDTH-1:0] bus_data_in,
    output logic [`WIDTH-1:0] bus_data_out,
    output logic [`WIDTH-1:0] bus_addr_in,
    output logic [3:0] bus_byteen,
    output logic bus_mem_read,
    output logic bus_mem_write,

    // pipeline stage pcs
    output logic [`WIDTH-1:0] o_pc_if,
    output logic [`WIDTH-1:0] o_pc_id,
    output logic [`WIDTH-1:0] o_pc_ex,
    output logic [`WIDTH-1:0] o_pc_mem,
    output logic [`WIDTH-1:0] o_pc_wb,
    
    // pipeline stage instrs
    output logic [`WIDTH-1:0] o_instruction_if,
    output logic [`WIDTH-1:0] o_instruction_id,
    output logic [`WIDTH-1:0] o_instruction_ex,
    output logic [`WIDTH-1:0] o_instruction_mem,
    output logic [`WIDTH-1:0] o_instruction_wb
);

    logic [`WIDTH-1:0] instruction_fetched;
    logic [`WIDTH-1:0] pc_if;

    /* verilator public_module */
    riscv_pipelined_core core(
        .i_clk(clk),
        .i_reset(reset),

        // instruction memory interface
        .i_instruction(instruction_fetched),
        .o_pc_if(pc_if),

        // data memory interface  
        .i_dmem_read_data(bus_data_out),
        .o_dmem_addr(bus_addr_in),
        .o_dmem_write_data(bus_data_in),
        .o_dmem_byteen(bus_byteen),
        .o_dmem_write_en(bus_mem_write),
        .o_dmem_read_en(bus_mem_read),
        
        // debug outs
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

    // Assign PC IF for debug output
    assign o_pc_if = pc_if;

    /* verilator public_module */
    dmem_bus #(.WIDTH(`WIDTH)) dbus(
        .clk(clk),

        // from core
        .data_in(bus_data_in),
        .mem_read(bus_mem_read),
        .mem_write(bus_mem_write),
        .addr_in(bus_addr_in),
        .byteen(bus_byteen),

        // to core
        .data_out(bus_data_out)
    );

    /* verilator public_module */
    imem_bus #(.WIDTH(`WIDTH)) ibus(
        .clk(clk),
        
        // from core
        .pc(pc_if),
        
        // to core
        .instruction_data_out(instruction_fetched)
    );

endmodule
