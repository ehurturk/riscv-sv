VERILATOR      = verilator
CXXFLAGS       = -std=c++14
VERILATOR_FLAGS = --cc --exe --build -Wall -j 0 -Isrc/definitions


SRC_DIR   = src
TB_DIR    = tb
BUILD_DIR = obj_dir

SV_SRCS   = $(addprefix $(SRC_DIR)/, alu.sv alu_control.sv control.sv datapath.sv regfile.sv ex.sv id.sv if.sv mem.sv mux2.sv mux3.sv top.sv wb.sv)
TB_CPP    = $(addprefix $(TB_DIR)/, sim_regfile.cpp sim_mux2.cpp sim_mux3.cpp sim_alu.cpp)
 
TOP_MODULE = top
BIN = riscv

.PHONY: all clean

all: $(BIN)

$(BIN): $(SV_SRCS) $(TB_CPP)
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOP_MODULE) \
		-CFLAGS "$(CXXFLAGS)" \
		$(SV_SRCS) $(TB_CPP) \
		-o $(BIN)

run_%:
	@echo "Building and running testbench for module '$*'"
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $* \
		-CFLAGS "$(CXXFLAGS)" \
		$(SV_SRCS) $(TB_DIR)/sim_$*.cpp \
		-o sim_$*
	./obj_dir/sim_$*

clean:
	rm -rf $(BUILD_DIR) $(BIN)

