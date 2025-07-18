# SystemVerilog RISC-V Core
![](docs/memory-ports.png)

Aim: Implement 5-stage pipelined RSIC-V core (RV32I ISA subset) using SystemVerilog, with these extensions:
- Hazard Unit
- Branch Prediction
- MMIO
- UART, SPI, I2C support

## TODO Modules
- [x] ALU
- [x] Register file
- [x] Branch Unit
- [x] Immediate Generator
- [x] ALU Control
- [x] Instruction Memory
- [x] Data Memory
- [x] Program Counter
- [x] Datapath
- [ ] Control Unit
- [ ] Pipelines
- [ ] Hazard Unit

## TODO
1) Implement CU
2) Test CU
4) Add checks for `TEXT_MEM_BEGIN` and `DATA_MEM_BEGIN` memory ranges in `dmem` and `imem`.