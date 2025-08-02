# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SystemVerilog RISC-V core implementation supporting the RV32I instruction set. The project implements three different processor architectures:
- **Single Cycle**: Basic single-cycle implementation  
- **Multicycle**: FSM-based multicycle implementation
- **Pipelined**: 5-stage pipelined implementation (work in progress)

The goal is to implement a complete 5-stage pipelined RISC-V core with hazard detection, branch prediction, and MMIO support.

## Architecture

### Core Components
- **ALU**: Arithmetic Logic Unit with operation control
- **Register File**: 32 registers with dual read ports and single write port
- **Memory System**: Separate instruction memory (imem) and data memory (dmem) with bus interfaces
- **Control Unit**: Generates control signals for datapath (single-cycle and multicycle variants)
- **Branch Unit**: Handles branch condition evaluation
- **Immediate Generator**: Extracts and sign-extends immediates from instructions

### Directory Structure
```
src/
├── definitions/           # SystemVerilog headers and type definitions
│   ├── control_bits.svh   # Control signal definitions
│   ├── defs.svh           # General definitions
│   └── type_enums.svh     # Enumerated types
├── modules/               # Reusable core modules
├── single_cycle/          # Single-cycle implementation
├── multicycle/            # Multicycle FSM implementation
└── pipelined/             # 5-stage pipelined implementation (WIP)
```

### Implementation Status
- ✅ Single Cycle: Complete and tested
- ✅ Multicycle: Complete with FSM-based control
- 🚧 Pipelined: In development (missing hazard unit)

## Build and Development Commands

### Primary Build Commands
```bash
# Build the complete processor
make all              # or just `make`

# Compile without running
make compile

# Clean build artifacts
make clean
make distclean        # Remove all generated files including waves
```

### Testing Commands
```bash
# Run all module tests
make test

# Test specific modules
make test_alu         # Test ALU module
make test_regfile     # Test register file
make test_dmem        # Test data memory
make test_imem        # Test instruction memory
make test_memory      # Test both memory modules

# Available testable modules: regfile, mux2, mux4, alu, dmem, imem
```

### Code Quality Commands
```bash
# Lint SystemVerilog code
make lint

# Format SystemVerilog files (requires verible-verilog-format)
make format

# Check if all source files exist
make check_sources
```

### Memory Initialization
```bash
# Initialize instruction memory with hex file
make init_imem MEM_DIR/program.hex

# Initialize data memory with hex file  
make init_dmem MEM_DIR/data.hex
```

### Waveform Analysis
```bash
# View waveforms (requires GTKWave)
make waves WAVE_DIR/filename.vcd

# Waveforms are automatically generated in waves/ directory during testing
```

## Key Architecture Details

### Memory Layout
- **Instruction Memory**: Contains program code loaded from .hex files
- **Data Memory**: Separate data memory with configurable base addresses
- **Memory Interfaces**: Bus-based interfaces for both instruction and data memory
- NOTE that unified memory is used in multicycle, hence in pipelined designs.
- 

### Control Signal Architecture
The control unit generates signals based on instruction opcodes:
- `CTL_RegWrite`: Enable register file writes
- `CTL_AluOp`: Select ALU operation type
- `CTL_AluSrc`: Select ALU operand B source
- `CTL_PcSel`: Select next PC source
- `CTL_MemRead/MemWrite`: Memory operation enables
- `CTL_MemToReg`: Select writeback data source

See `docs/CONTROL-SC.md` and `docs/CONTROL-MC.md` for detailed control signal specifications.

For multicycle desings, a finite state machine is being used.

### Pipeline Stages (Target Implementation)
1. **IF**: Instruction Fetch
2. **ID**: Instruction Decode & Register Read
3. **EX**: Execute (ALU operations, branch resolution)
4. **MEM**: Memory Access (load/store operations)
5. **WB**: Writeback to register file

## Development Notes

### Current Branch: feature/pipelined
Working on pipelined implementation. Recent commits show multicycle implementation is complete.

### Testing Strategy
- Individual module testbenches in `tb/` directory
- Comprehensive instruction tests using assembly programs in `asm/`
- Waveform analysis for debugging timing and functionality

### Memory Files
Test programs and initialization files are stored in:
- `asm/`: Assembly source files
- `mem/`: Compiled hex files for memory initialization

### Tools Required
- **Verilator**: For simulation and compilation
- **GTKWave**: For waveform viewing
- **RISC-V Toolchain**: For assembly compilation (if modifying test programs)
- **verible-verilog-format**: For code formatting (optional)

## Configuration Files
Each implementation has its own `config.svh` file defining architecture-specific parameters and memory layouts.