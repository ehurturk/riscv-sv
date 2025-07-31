// multi cycle control unit FSM

`include "../definitions/type_enums.svh"
`include "../definitions/defs.svh"

typedef enum logic [4:0] { 
    // common states (to all instrs)
    FETCH         = 5'b00000,
    DECODE        = 5'b00001,

    // loads/stores
    MEM_ADDR_COMP = 5'b00010, // l/s
    MEM_READ      = 5'b00011, // l
    MEM_WRITE     = 5'b00100, // s
    MEM_WB        = 5'b00101, // l

    // execution states
    EXECUTE_R     = 5'b00110,
    EXECUTE_I     = 5'b00111,
    ALU_WB        = 5'b01000,

    BRANCH        = 5'b01001,

    JAL           = 5'b01010,
    JALR          = 5'b01011,
    LUI           = 5'b01100,
    AUIPC         = 5'b01101,

    FENCE        = 5'b01110,
    SYSTEM        = 5'b01111
} state_t;

module mccontrol (
    input logic clk,
    input logic reset,

    input logic [6:0] instr_opc,

    output logic CTL_IorD,
    output logic CTL_MemWrite,
    output logic CTL_MemRead,
    output logic CTL_IRWrite,
    output logic CTL_RegWrite,
    output logic [1:0] CTL_MemToReg,
    output logic [1:0] CTL_PCSrc,
    output logic CTL_PCWriteCond,
    output logic CTL_PCWrite,
    output logic [1:0] CTL_ALUSrcA,
    output logic [2:0] CTL_ALUSrcB,
    output aluop_t CTL_ALUOp
);

state_t state, next_state;

// state register
always_ff @( posedge clk ) begin
    if (reset) begin
        state <= FETCH;
    end

    else begin
        state <= next_state;
    end    
end

// state logic
always_comb begin : state_logic
    next_state = state;
    case (state)
        FETCH: begin
            next_state = DECODE;
        end 

        DECODE: begin
            case (instr_opc)
                `OPC_ITYPE_L: next_state = MEM_ADDR_COMP;
                `OPC_STYPE:   next_state = MEM_ADDR_COMP;
                `OPC_RTYPE:   next_state = EXECUTE_R;
                `OPC_ITYPE:   next_state = EXECUTE_I;
                `OPC_JTYPE:   next_state = JAL;
                `OPC_ITYPE_J: next_state = JALR;
                `OPC_BTYPE:   next_state = BRANCH;
                `OPC_UTYPE_A: next_state = AUIPC;
                `OPC_UTYPE_L: next_state = LUI;
                `OPC_ITYPE_F: next_state = FENCE;
                `OPC_ITYPE_E: next_state = SYSTEM;
                default:      next_state = FETCH;
            endcase
        end

        MEM_ADDR_COMP: begin
            case (instr_opc)
                `OPC_ITYPE_L: next_state = MEM_READ;
                `OPC_STYPE:   next_state = MEM_WRITE;
                default:      next_state = FETCH;
            endcase
        end

        MEM_READ:  next_state = MEM_WB;
        MEM_WB:    next_state = FETCH;
        MEM_WRITE: next_state = FETCH;

        EXECUTE_R: next_state = ALU_WB;
        EXECUTE_I: next_state = ALU_WB;
        JAL:       next_state = FETCH; // fetch?
        JALR:      next_state = FETCH; // fetch?

        ALU_WB:    next_state = FETCH;

        BRANCH:    next_state = FETCH;

        AUIPC:     next_state = ALU_WB;
        LUI:       next_state = FETCH;
        default:   next_state = FETCH;
    endcase
end

// output logic (as a moore machine)
always_comb begin : output_logic
    // reset
    CTL_IorD = 0;
    CTL_MemWrite = 0;
    CTL_MemRead = 0;
    CTL_IRWrite = 0;
    CTL_RegWrite = 0;
    CTL_MemToReg = 0;
    CTL_PCSrc = 0;
    CTL_PCWriteCond = 0;
    CTL_PCWrite = 0;
    CTL_ALUSrcA = 0;
    CTL_ALUSrcB = 0;
    CTL_ALUOp = ALUOP_ADD;

    case (state)
        FETCH: begin
            CTL_IorD = 0;
            CTL_MemRead = 1;
            CTL_ALUSrcA = 2'b00;      // PC
            CTL_IRWrite = 1;
            CTL_ALUSrcB = 3'b001;     // 4
            CTL_ALUOp = ALUOP_ADD;    // Calculate PC+4
            CTL_PCWrite = 0;          // DON'T update PC here!
            CTL_PCSrc = 2'b00;
        end


        // DECODE: begin
        //     CTL_ALUSrcA = 2'b00;
        //     CTL_ALUSrcB = 3'b010;
        //     CTL_ALUOp = ALUOP_ADD;
        //     // TODO: precalculate the branch target - branch prediction
        // end

        DECODE: begin
            CTL_ALUSrcA = 2'b00;      // PC
            CTL_ALUSrcB = 3'b010;     // Immediate
            CTL_ALUOp = ALUOP_ADD;    // Calculate branch target
            // Add PC update for sequential execution
            CTL_PCWrite = 1;          // Update PC now!
            CTL_PCSrc = 2'b01;        // From ALUOut (which has PC+4 from FETCH)
        end

        MEM_ADDR_COMP: begin
            CTL_ALUSrcA = 2'b01;  // A
            CTL_ALUSrcB = 3'b010; // Imm
            CTL_ALUOp = ALUOP_ADD;
        end
        
        MEM_READ: begin
            CTL_MemRead = 1'b1;
            CTL_IorD = 1'b1;      // Mem Interface Address In: ALUOut
        end
        
        MEM_WRITE: begin
            CTL_MemWrite = 1'b1;
            CTL_IorD = 1'b1;      // Use ALUOut for address
        end
        
        MEM_WB: begin
            CTL_RegWrite = 1'b1;
            CTL_MemToReg = 2'b01; // MDR
        end

        ALU_WB: begin
            CTL_RegWrite = 1'b1;
            CTL_MemToReg = 2'b00;
        end

        EXECUTE_R: begin
            CTL_ALUSrcA = 2'b01;
            CTL_ALUSrcB = 3'b000;
            CTL_ALUOp = ALUOP_RTYPE;
        end
            
        EXECUTE_I: begin
            CTL_ALUSrcA = 2'b01;
            CTL_ALUSrcB = 3'b010;
            CTL_ALUOp = ALUOP_ITYPE;
        end

        BRANCH: begin
            CTL_ALUSrcA = 2'b01;  // A
            CTL_ALUSrcB = 3'b000; // B
            CTL_ALUOp = ALUOP_SUB; 
            CTL_PCWriteCond = 1'b1;
            CTL_PCSrc = 2'b01;    // ALUOut
        end
        
        JAL: begin
            CTL_PCWrite = 1'b1;
            CTL_PCSrc = 2'b01;    // ALUOut
            CTL_RegWrite = 1'b1;
            CTL_MemToReg = 2'b10; // PC
        end

        JALR: begin
            CTL_ALUSrcA = 2'b01;  // A register
            CTL_ALUSrcB = 3'b010; // Immediate
            CTL_ALUOp = ALUOP_ADD;
            CTL_PCWrite = 1'b1;
            CTL_PCSrc = 2'b10;    // PC = R[rs1]+imm (alu_result)
            CTL_RegWrite = 1'b1;
            CTL_MemToReg = 2'b10;
        end

        LUI: begin
            CTL_RegWrite = 1'b1;
            CTL_ALUSrcA = 2'b10;  // Zero
            CTL_ALUSrcB = 3'b010; // Immediate
            CTL_ALUOp = ALUOP_ADD;
            CTL_MemToReg = 2'b00; // ALUOut
        end
        
        AUIPC: begin
            CTL_RegWrite = 1'b1;
            CTL_ALUSrcA = 2'b00;  // PC
            CTL_ALUSrcB = 3'b010; // Immediate
            CTL_ALUOp = ALUOP_ADD;
            CTL_MemToReg = 2'b00; // ALUOut
        end
        
        FENCE: begin
            // NOP for now
            // TODO
        end
        
        SYSTEM: begin
            // ECALL/EBREAK - NOP for now
            // In a real implementation, would trap
        end

        default: begin
            
        end

    endcase
end

endmodule : mccontrol
