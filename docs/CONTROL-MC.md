# Control Unit & Control Signals

## Multi Cycle Datapath

### Instruction Fetch
```
IR <= Mem[PC];
PC <= PC+4;
```
*Control Signals*:
- MemRead = 1
- IRWrite = 1
- IorD    = 0   -> addr  = PC
- ALUSrcA = 0   -> ALUA  = PC
- ALUSrcB = 01  -> ALUB  = 4
- ALUOp   = 00  -> ALUOp = ADD
- PCSrc   = 0   -> PCSrc = PC+4
- PCWrite = 1

### Instruction Decode & Register Fetch
```
A <= Reg[IR[19:15]]
B <= Reg[IR[24:20]]
ALUOut <= PC + Imm // for branch target
```

*Control Signals*
- ALUSrcA = 0  -> ALUA = PC
- ALUSrcB = 10 -> ALUB = Imm
- ALUOp   = 00 -> ALUOp = ADD
- 

