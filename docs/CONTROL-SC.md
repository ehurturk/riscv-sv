# Control Unit & Control Signals

## Single Cycle Datapath

### Control Signals

| Control Signal    | Width | Description |
| ----------------- | ----- | ----------- |
| CTL_RegWrite      | 1 bit | Enables writing to the register file. 1 = write result to destination register, 0 = no write |
| CTL_AluOp         | 2 bits | Selects ALU operation type: 00 = ADD (loads/stores), 01 = SUB (branches), 10 = R-type decode, 11 = I-type decode |
| CTL_AluSrc        | 1 bit | Selects ALU operand B source: 0 = register data (rs2), 1 = immediate value |
| CTL_PcSel         | 2 bits | Selects next PC source: 00 = PC+4, 01 = PC+immediate (branches/JAL), 10 = ALU result (JALR), 11 = reserved |
| CTL_BranchEnable  | 1 bit | Enables branch condition evaluation. 1 = evaluate branch condition, 0 = no branch |
| CTL_MemRead       | 1 bit | Enables data memory read operation. 1 = read from memory, 0 = no read |
| CTL_MemWrite      | 1 bit | Enables data memory write operation. 1 = write to memory, 0 = no write |
| CTL_MemToReg      | 3 bits | Selects data to write back to register: 000 = ALU result, 001 = memory data, 010 = PC+4, 011 = immediate, 100 = PC+immediate |

### Input Signals

| Input Signal | Width | Description |
| ------------ | ----- | ----------- |
| take_branch  | 1 bit | Signal from branch unit indicating if branch condition is met |
| inst_opc     | 7 bits | Instruction opcode field (bits `instruction[6:0]`) used to determine instruction type |

### Control Signal Usage by Instruction Type

| Instruction Type | RegWrite | AluOp | AluSrc | PcSel | BranchEnable | MemRead | MemWrite | MemToReg |
| ---------------- | -------- | ----- | ------ | ----- | ------------ | ------- | -------- | -------- |
| R-type           | 1        | 10    | 0      | 00    | 0            | 0       | 0        | 000      |
| I-type (arith)   | 1        | 11    | 1      | 00    | 0            | 0       | 0        | 000      |
| I-type (load)    | 1        | 00    | 1      | 00    | 0            | 1       | 0        | 001      |
| S-type (store)   | 0        | 00    | 1      | 00    | 0            | 0       | 1        | XXX      |
| SB-type (branch) | 0        | 01    | 0      | 00/01 | 1            | 0       | 0        | XXX      |
| U-type (LUI)     | 1        | XX    | X      | 00    | 0            | 0       | 0        | 011      |
| U-type (AUIPC)   | 1        | 00    | 1      | 00    | 0            | 0       | 0        | 100      |
| UJ-type (JAL)    | 1        | XX    | X      | 01    | 0            | 0       | 0        | 010      |
| I-type (JALR)    | 1        | 00    | 1      | 10    | 0            | 0       | 0        | 010      |
