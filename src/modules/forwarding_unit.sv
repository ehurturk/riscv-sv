// module: forwarding unit
// description: generates necessary forward signals that allow the EX stage to have forwarded data

module forward_unit (
    input logic [4:0] i_id_rs1,
    input logic [4:0] i_id_rs2,
    input logic [4:0] i_ex_rs1,
    input logic [4:0] i_ex_rs2,

    input logic [31:0] i_dmem_out, // mem stage data

    input logic [4:0] i_ex_mem_rd,
    input logic i_ex_mem_reg_write,
    input logic [4:0] i_mem_wb_rd,
    input logic i_mem_wb_reg_write,
    // input logic [31:0] i_ex_mem_alu_res,
    // input logic [31:0] i_mem_wb_write_data,

    output logic [1:0] o_forward_a,
    output logic [1:0] o_forward_b
);



endmodule