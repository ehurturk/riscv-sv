`include "../definitions/control_bits.svh"
`include "../definitions/defs.svh"
`include "../definitions/type_enums.svh"

module control (
	input logic take_branch,
	input logic [6:0] inst_opc,

	output logic CTL_RegWrite,
	output aluop_t CTL_AluOp,
	output logic CTL_AluSrc,
	output logic [1:0] CTL_PcSel,
	output logic CTL_BranchEnable,
	output logic CTL_MemRead,
	output logic CTL_MemWrite,
	output logic [2:0] CTL_MemToReg
);


assign CTL_RegWrite = 1'b0;
assign CTL_AluSrc = 1'b0;
assign CTL_BranchEnable = 1'b0;
assign CTL_MemRead = 1'b0;
assign CTL_MemWrite = 1'b0;
assign CTL_AluOp = ALUOP_ADD;
assign CTL_MemToReg = 3'b000;

always_comb begin
	case (inst_opc)
		`OPC_BTYPE:   CTL_PcSel = take_branch ? `CTL_PCSEL_PCPLUSIMM : `CTL_PCSEL_PCPLUS4;
		`OPC_JTYPE:   CTL_PcSel = `CTL_PCSEL_PCPLUSIMM; // JAL
		`OPC_ITYPE_J: CTL_PcSel = `CTL_PCSEL_RPLUSIMM;  // JALR
		default :     CTL_PcSel = `CTL_PCSEL_PCPLUS4; 
	endcase
end

endmodule : control
