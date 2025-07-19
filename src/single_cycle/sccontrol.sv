`include "../definitions/control_bits.svh"
`include "../definitions/defs.svh"
`include "../definitions/type_enums.svh"

module sccontrol (
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

always_comb begin
    // default vals
    CTL_RegWrite = 1'b0;
    CTL_AluOp = ALUOP_ADD;
    CTL_AluSrc = 1'b0;
    CTL_BranchEnable = 1'b0;
    CTL_MemRead = 1'b0;
    CTL_MemWrite = 1'b0;
    CTL_MemToReg = 3'b000;
    
    case (inst_opc)
        `OPC_RTYPE: begin
            CTL_RegWrite = 1'b1;
            CTL_AluOp = ALUOP_RTYPE;
            CTL_AluSrc = 1'b0;
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'b000;        // alu out
        end
        
        `OPC_ITYPE: begin
            CTL_RegWrite = 1'b1;
            CTL_AluOp = ALUOP_ITYPE;      
            CTL_AluSrc = 1'b1;
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'b000;        // alu out
        end
        
        `OPC_ITYPE_L: begin
            CTL_RegWrite = 1'b1;
            CTL_AluOp = ALUOP_ADD;
            CTL_AluSrc = 1'b1;
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b1;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'b001;       // mem data
        end
        
        `OPC_STYPE: begin
            CTL_RegWrite = 1'b0;
            CTL_AluOp = ALUOP_ADD;
            CTL_AluSrc = 1'b1;
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b1;
            CTL_MemToReg = 3'bxxx;
        end
        
        `OPC_BTYPE: begin
            CTL_RegWrite = 1'b0;
            CTL_AluOp = ALUOP_SUB;        // force sub
            CTL_AluSrc = 1'b0;
            CTL_BranchEnable = 1'b1;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'bxxx;        
        end
        
        `OPC_UTYPE_L: begin
            CTL_RegWrite = 1'b1;
            CTL_AluOp = ALUOP_ADD;        // dont care
            CTL_AluSrc = 1'bx;            
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'b011;        // imm
        end
        
        `OPC_UTYPE_A: begin              // AIUPC
            CTL_RegWrite = 1'b1;
            CTL_AluOp = ALUOP_ADD;
            CTL_AluSrc = 1'b1;
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'b100;        // pc + imm
        end
        
        `OPC_JTYPE: begin
            CTL_RegWrite = 1'b1;
            CTL_AluOp = ALUOP_ADD;        // XX
            CTL_AluSrc = 1'bx;            // X
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'b010;        // PC + 4
        end
        
        `OPC_ITYPE_J: begin
            CTL_RegWrite = 1'b1;
            CTL_AluOp = ALUOP_ADD;        
            CTL_AluSrc = 1'b1;
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'b010;        // PC + 4
        end

        `OPC_ITYPE_F: begin
            // FENCE is essentially a NOP in single cycle
            CTL_RegWrite = 1'b0;
            CTL_AluOp = ALUOP_ADD;
            CTL_AluSrc = 1'b0;
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'b000;
        end
        
        // ECALL/EBREAK
        `OPC_ITYPE_E: begin
            // TODO: implement a trap (now a NOP)
            CTL_RegWrite = 1'b0;
            CTL_AluOp = ALUOP_ADD;
            CTL_AluSrc = 1'b0;
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'b000;
        end
        
        default: begin
            CTL_RegWrite = 1'b0;
            CTL_AluOp = ALUOP_ADD;
            CTL_AluSrc = 1'b0;
            CTL_BranchEnable = 1'b0;
            CTL_MemRead = 1'b0;
            CTL_MemWrite = 1'b0;
            CTL_MemToReg = 3'b000;
        end
    endcase
end

always_comb begin
    case (inst_opc)
        `OPC_BTYPE:   CTL_PcSel = take_branch ? `CTL_PCSEL_PCPLUSIMM : `CTL_PCSEL_PCPLUS4;
        `OPC_JTYPE:   CTL_PcSel = `CTL_PCSEL_PCPLUSIMM;  // JAL
        `OPC_ITYPE_J: CTL_PcSel = `CTL_PCSEL_RPLUSIMM;   // JALR
        default:      CTL_PcSel = `CTL_PCSEL_PCPLUS4;
    endcase
end

endmodule
