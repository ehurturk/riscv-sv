# SystemVerilog RISC-V Core
![](docs/pipelined_without_hu.png)

Aim: Implement 5-stage pipelined RSIC-V core (RV32I ISA subset) using SystemVerilog, with these extensions:
- Hazard Unit
- Branch Prediction
- etc...

## TODO Modules
- [x] ALU
- [x] Register file
- [x] Branch Unit
- [x] Immediate Generator
- [x] ALU Control
- [ ] Control Unit
- [ ] Instruction Memory
- [ ] Data Memory
- [ ] Program Counter
- [ ] Datapath
- [ ] Pipelines
- [ ] Hazard Unit

## TODO
1) Write testbenches for imm generation + ALU signal generation
2) Write DataMemory + InstructionMemory
3) Start planning control signals + CU

---

1) Implement CU
2) Test CU
3) Wire everything for a single cycle datapath

---
1) Test multicycle datapath