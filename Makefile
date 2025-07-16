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

BASIC_SRCS      = mux2.sv mux4.sv mux8.sv
CORE_SRCS       = alu.sv alu_control.sv immgen.sv branch_unit.sv regfile.sv control.sv
MEM_SRCS        = dmem.sv dmem_bus.sv dmem_interface.sv imem.sv imem_bus.sv
STAGE_SRCS      = if.sv id.sv ex.sv mem.sv wb.sv
TOP_SRCS        = datapath.sv top.sv
SV_SRCS         = $(addprefix $(SRC_DIR)/, $(BASIC_SRCS) $(CORE_SRCS) $(MEM_SRCS) $(STAGE_SRCS) $(TOP_SRCS))

# Testbench Files
TESTABLE_MODULES = regfile mux2 mux4 alu dmem imem

TOP_MODULE      = top
TOP_BIN         = riscv

# ==========================================
# Build Targets
# ==========================================

.PHONY: all clean test help waves compile

all: $(TOP_BIN)

# Build the main RISC-V processor
$(TOP_BIN): $(SV_SRCS)
	@echo "Building RISC-V processor..."
	@$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOP_MODULE) \
		-CFLAGS "$(CXXFLAGS)" \
		$(SV_SRCS) \
		-o $(TOP_BIN)
	@echo "Build complete: $(BUILD_DIR)/$(TOP_BIN)"

# Module dependencies
DEPS_dmem_interface = $(SRC_DIR)/dmem_interface.sv
DEPS_dmem_bus = $(SRC_DIR)/dmem_bus.sv $(SRC_DIR)/dmem.sv
DEPS_dmem = $(DEPS_dmem_bus) $(DEPS_dmem_interface)
DEPS_data_memory = $(SRC_DIR)/dmem.sv
DEPS_imem_bus = $(SRC_DIR)/imem_bus.sv $(SRC_DIR)/imem.sv

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
	@rm -f $(TOP_BIN)
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
	@echo "RISC-V Single Cycle Processor Makefile"
	@echo "======================================"
	@echo "Available targets:"
	@echo "  all           - Build the complete processor (default)"
	@echo "  test_<module> - Build and run testbench for specific module"
	@echo "  test          - Run all available module tests"
	@echo "  test_memory   - Run memory system tests (dmem + imem)"
	@echo "  compile       - Compile only, don't run"
	@echo "  clean         - Remove build artifacts"
	@echo "  distclean     - Remove all generated files"
	@echo "  help          - Show this help message"
	@echo ""
	@echo "Testable modules: $(TESTABLE_MODULES)"
	@echo ""
	@echo "Examples:"
	@echo "  make test_alu    - Test the ALU module"
	@echo "  make test_dmem   - Test the dmem module"
	@echo "  make test_imem   - Test the imem module"
	@echo "  make test        - Run all tests"
	@echo "  make clean all   - Clean rebuild"

print_sources:
	@echo "SystemVerilog sources:"
	@for src in $(SV_SRCS); do echo "  $$src"; done

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