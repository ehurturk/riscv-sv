# RISC-V Architecture 
A RV32I core implementation on SystemVerilog

## Pipelines
This is a 5-stage pipelined RISC-V architecture:
- IF: Instruction fetch
- ID: Instruction decode
- EX: Execute
- MEM: Read/Write from/to memory
- WB: Write back to register file

## Extensions
- Hazard Unit
- Branch Prediction