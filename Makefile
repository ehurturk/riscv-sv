VERILATOR       = verilator
VERILATOR_FLAGS = --cc --exe --build -Wall -j 0
VERILATOR_FLAGS += -Wno-DECLFILENAME -Wno-WIDTH -Wno-UNUSED
VERILATOR_FLAGS += --trace --trace-structs
VERILATOR_FLAGS += -Isrc/definitions

CXX             = g++
CXXFLAGS        = -std=c++14 -Wall -O2
LDFLAGS         = 

SRC_DIR         = src
TB_DIR          = tb
BUILD_DIR       = obj_dir
WAVE_DIR        = waves
MEM_DIR         = mem
ASM_DIR         = asm

# Create directories if they don't exist
$(shell mkdir -p $(WAVE_DIR) $(MEM_DIR))

# Common modules used by all variants
BASIC_SRCS      = modules/mux2.sv modules/mux4.sv modules/mux8.sv
CORE_SRCS       = modules/alu.sv modules/alu_control.sv modules/immgen.sv modules/branch_unit.sv modules/regfile.sv
MEM_SRCS        = modules/dmem.sv modules/dmem_bus.sv modules/dmem_interface.sv modules/imem.sv modules/imem_bus.sv modules/memory_bus.sv
COMMON_SRCS     = $(addprefix $(SRC_DIR)/, $(BASIC_SRCS) $(CORE_SRCS) $(MEM_SRCS))

# Single cycle specific sources
SC_SRCS         = single_cycle/datapath.sv single_cycle/sccontrol.sv single_cycle/riscv_sc_core.sv single_cycle/top.sv
SC_SV_SRCS      = $(COMMON_SRCS) $(addprefix $(SRC_DIR)/, $(SC_SRCS))

# Multicycle specific sources  
MC_SRCS         = multicycle/multicycle_datapath.sv multicycle/mccontrol.sv multicycle/riscv_mc_core.sv multicycle/top.sv
MC_SV_SRCS      = $(COMMON_SRCS) $(addprefix $(SRC_DIR)/, $(MC_SRCS))

# Pipelined specific sources
PL_SRCS         = pipelined/pipelined_datapath.sv pipelined/pipelined_control.sv pipelined/riscv_pipelined_core.sv pipelined/top.sv pipelined/hazard_unit.sv
PL_SV_SRCS      = $(COMMON_SRCS) $(addprefix $(SRC_DIR)/, $(PL_SRCS))

# Legacy support - defaults to single cycle
SV_SRCS         = $(SC_SV_SRCS)

# Testbench Files
TESTABLE_MODULES = regfile mux2 mux4 alu dmem imem

TOP_MODULE      = top
TOP_BIN         = riscv

# ==========================================
# Build Targets
# ==========================================

.PHONY: all clean test help waves compile single-cycle multicycle pipelined sc mc pl all-variants print_sources print_sources_sc print_sources_mc print_sources_pl print_config check_sources

# Default target builds single cycle
all: single-cycle

# ==========================================
# Processor Variant Build Targets
# ==========================================

# Single Cycle Processor
single-cycle sc: riscv-sc
	@echo "Single cycle RISC-V processor built: $(BUILD_DIR)/riscv-sc"

riscv-sc: $(SC_SV_SRCS)
	@echo "Building Single Cycle RISC-V processor..."
	@$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module top \
		-CFLAGS "$(CXXFLAGS)" \
		$(SC_SV_SRCS) \
		-o riscv-sc
	@echo "Build complete: $(BUILD_DIR)/riscv-sc"

# Multicycle Processor  
multicycle mc: riscv-mc
	@echo "Multicycle RISC-V processor built: $(BUILD_DIR)/riscv-mc"

riscv-mc: $(MC_SV_SRCS)
	@echo "Building Multicycle RISC-V processor..."
	@$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module top \
		-CFLAGS "$(CXXFLAGS)" \
		$(MC_SV_SRCS) \
		tb/sim_mctop.cpp
		-o riscv-mc
	@echo "Build complete: $(BUILD_DIR)/riscv-mc"

# Pipelined Processor
pipelined pl: riscv-pl
	@echo "Pipelined RISC-V processor built: $(BUILD_DIR)/riscv-pl"

riscv-pl: $(PL_SV_SRCS)
	@echo "Building Pipelined RISC-V processor..."
	@$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module top \
		-CFLAGS "$(CXXFLAGS)" \
		$(PL_SV_SRCS) \
		tb/sim_pipelined.cpp \
		-o riscv-pl
	@echo "Build complete: $(BUILD_DIR)/riscv-pl"

# Build all variants
all-variants: single-cycle multicycle pipelined
	@echo "All RISC-V processor variants built successfully!"

# Legacy target for backward compatibility
$(TOP_BIN): riscv-sc
	@ln -sf riscv-sc $(BUILD_DIR)/$(TOP_BIN) 2>/dev/null || true

# Module dependencies
DEPS_dmem_interface = $(SRC_DIR)/modules/dmem_interface.sv
DEPS_dmem_bus = $(SRC_DIR)/modules/dmem_bus.sv $(SRC_DIR)/modules/dmem.sv
DEPS_dmem = $(DEPS_dmem_bus) $(DEPS_dmem_interface)
DEPS_data_memory = $(SRC_DIR)/modules/dmem.sv
DEPS_imem_bus = $(SRC_DIR)/modules/imem_bus.sv $(SRC_DIR)/modules/imem.sv

# Generic rule for building and running individual module tests
test_%: $(TB_DIR)/sim_%.cpp
	@if [ ! -f "$<" ]; then \
		echo "Error: Testbench $< not found!"; \
		exit 1; \
	fi
	@echo "========================================"
	@echo "Testing module: $*"
	@echo "========================================"
	@# Determine which files to compile
	@if [ -n "$(DEPS_$*)" ]; then \
		COMPILE_SRCS="$(DEPS_$*)"; \
	else \
		COMPILE_SRCS="$(SV_SRCS)"; \
	fi; \
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $* \
		-CFLAGS "$(CXXFLAGS)" \
		$$COMPILE_SRCS $< \
		-o sim_$*
	@echo "Running test..."
	@./$(BUILD_DIR)/sim_$*
	@if [ -f "$*.vcd" ]; then \
		mv $*.vcd $(WAVE_DIR)/; \
		echo "Waveform saved: $(WAVE_DIR)/$*.vcd"; \
	fi
	@echo ""

# Run all available tests
test: $(addprefix test_, $(TESTABLE_MODULES))
	@echo "========================================"
	@echo "All tests completed!"
	@echo "========================================"

# Special target for memory system tests
test_memory: test_dmem test_imem
	@echo "Memory system tests completed!"

# Compile only
compile: $(TOP_BIN)

# ==========================================
# Utility Targets
# ==========================================

# Generate and view waveforms
waves: $(WAVE_DIR)/%.vcd
	@echo "Opening waveform viewer..."
	@gtkwave $< &

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -f $(TOP_BIN) riscv-sc riscv-mc riscv-pl
	@rm -f *.vcd
	@rm -rf $(WAVE_DIR)/*.vcd
	@echo "Clean complete!"

distclean: clean
	@rm -rf $(WAVE_DIR)
	@rm -f $(MEM_DIR)/*.hex
	@echo "Distribution clean complete!"

# ==========================================
# Memory Initialization
# ==========================================

# Initialize instruction memory with a hex file
init_imem: $(MEM_DIR)/%.hex
	@echo "Initializing instruction memory with $<"
	@cp $< $(MEM_DIR)/program.hex

# Initialize data memory with a hex file  
init_dmem: $(MEM_DIR)/%.hex
	@echo "Initializing data memory with $<"
	@cp $< $(MEM_DIR)/data.hex

help:
	@echo "RISC-V Processor Makefile"
	@echo "========================="
	@echo "Processor Variant Build Targets:"
	@echo "  all              - Build single cycle processor (default)"
	@echo "  single-cycle, sc - Build single cycle processor"
	@echo "  multicycle, mc   - Build multicycle processor"
	@echo "  pipelined, pl    - Build pipelined processor"
	@echo "  all-variants     - Build all processor variants"
	@echo ""
	@echo "Testing Targets:"
	@echo "  test_<module>    - Build and run testbench for specific module"
	@echo "  test             - Run all available module tests"
	@echo "  test_memory      - Run memory system tests (dmem + imem)"
	@echo ""
	@echo "Utility Targets:"
	@echo "  clean            - Remove build artifacts"
	@echo "  distclean        - Remove all generated files"
	@echo "  compile          - Compile only, don't run"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Testable modules: $(TESTABLE_MODULES)"
	@echo ""
	@echo "Examples:"
	@echo "  make sc          - Build single cycle processor"
	@echo "  make mc          - Build multicycle processor"  
	@echo "  make pl          - Build pipelined processor"
	@echo "  make all-variants- Build all three variants"
	@echo "  make test_alu    - Test the ALU module"
	@echo "  make clean mc    - Clean rebuild multicycle"

print_sources:
	@echo "SystemVerilog sources (legacy/single-cycle):"
	@for src in $(SV_SRCS); do echo "  $$src"; done

print_sources_sc:
	@echo "Single Cycle SystemVerilog sources:"
	@for src in $(SC_SV_SRCS); do echo "  $$src"; done

print_sources_mc:
	@echo "Multicycle SystemVerilog sources:"
	@for src in $(MC_SV_SRCS); do echo "  $$src"; done

print_sources_pl:
	@echo "Pipelined SystemVerilog sources:"
	@for src in $(PL_SV_SRCS); do echo "  $$src"; done

print_config:
	@echo "Build Configuration:"
	@echo "  VERILATOR_FLAGS: $(VERILATOR_FLAGS)"
	@echo "  CXXFLAGS: $(CXXFLAGS)"
	@echo "  TOP_MODULE: $(TOP_MODULE)"
	@echo "  BUILD_DIR: $(BUILD_DIR)"

check_sources:
	@echo "Checking source files..."
	@missing=0; \
	for src in $(SV_SRCS); do \
		if [ ! -f "$$src" ]; then \
			echo "  MISSING: $$src"; \
			missing=$$((missing + 1)); \
		fi; \
	done; \
	if [ $$missing -eq 0 ]; then \
		echo "  All source files found!"; \
	else \
		echo "  $$missing source files missing!"; \
		exit 1; \
	fi

# Run Verilator in lint-only mode
lint:
	@echo "Running Verilator lint..."
	@$(VERILATOR) --lint-only $(VERILATOR_FLAGS) $(SV_SRCS)

# Format SystemVerilog files (requires verible-verilog-format)
format:
	@echo "Formatting SystemVerilog files..."
	@find $(SRC_DIR) -name "*.sv" -o -name "*.svh" | xargs verible-verilog-format --inplace

# Include dependencies if they exist
-include $(BUILD_DIR)/*.d