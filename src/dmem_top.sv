module dmem_top #(
    parameter WIDTH = 32
)(
    input  logic             clk,
    input  logic             mem_read,
    input  logic             mem_write,
    input  logic [2:0]       func3,
    input  logic [WIDTH-1:0] address_in,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);

    logic [WIDTH-1:0] bus_addr;
    logic [WIDTH-1:0] bus_data_in;
    logic [3:0]       bus_byteen;
    logic             bus_we, bus_re;
    logic [WIDTH-1:0] bus_data_out;

    dmem_interface dmem_interface_inst (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .func3(func3),
        .address_in(address_in),
        .data_in(data_in),
        .bus_data_out(bus_data_out),
        .data_out(data_out),
        .bus_addr(bus_addr),
        .bus_data_in(bus_data_in),
        .bus_byteen(bus_byteen),
        .bus_we(bus_we),
        .bus_re(bus_re)
    );

    dmem_bus dmem_bus_inst (
        .clk(clk),
        .mem_read(bus_re),
        .mem_write(bus_we),
        .addr_in(bus_addr),
        .data_in(bus_data_in),
        .byteen(bus_byteen),
        .data_out(bus_data_out)
    );

endmodule
