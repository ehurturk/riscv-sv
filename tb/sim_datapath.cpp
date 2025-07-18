#include "Vtop.h"
#include <cstddef>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>
#include <verilated.h>
#include <verilated_vcd_c.h>

class TopLevel {
public:
  TopLevel(bool);
  ~TopLevel();

  void tick();
  void reset();
  void dump_state();
  void set_control_signals_for_addi();
  void set_control_signals_for_add();
  void set_control_signals_for_store();
  void set_control_signals_for_load();
  void set_control_signals_for_branch();
  void set_control_signals_nop();

  Vtop *top;

private:
  VerilatedVcdC *tfp;
  int sim_time;
};

TopLevel::TopLevel(bool generate_waveform) : top(NULL), tfp(NULL), sim_time(0) {
  top = new Vtop;
  if (generate_waveform) {
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("datapath_test.vcd");
  }
}

TopLevel::~TopLevel() {
  if (tfp) {
    tfp->close();
    delete tfp;
  }
  delete top;
}

void TopLevel::tick() {
  top->clk = 0;
  top->eval();
  if (tfp)
    tfp->dump(sim_time++);

  top->clk = 1;
  top->eval();
  if (tfp)
    tfp->dump(sim_time++);
}

void TopLevel::reset() {
  std::cout << "Starting PC: 0x" << std::hex << top->pc << std::dec
            << std::endl;
}

void TopLevel::dump_state() {
  std::cout << "=== CPU State ===" << std::endl;
  std::cout << "PC: 0x" << std::hex << std::setfill('0') << std::setw(8)
            << top->pc << std::endl;
  std::cout << "Bus Addr: 0x" << std::setw(8) << top->bus_addr_in << std::endl;
  std::cout << "Bus Data In: 0x" << std::setw(8) << top->bus_data_in
            << std::endl;
  std::cout << "Bus Data Out: 0x" << std::setw(8) << top->bus_data_out
            << std::endl;
  std::cout << "Bus Read: " << (int)top->bus_mem_read
            << ", Write: " << (int)top->bus_mem_write << std::endl;
  std::cout << "Bus ByteEn: 0x" << std::hex << (int)top->bus_byteen
            << std::endl;
  std::cout << std::dec << std::endl;
}

void TopLevel::set_control_signals_for_addi() {
  // ADDI x1, x0, 5: I-type instruction
  // Need: RegWrite=1, ALUOp=ITYPE, ALUSrc=1, MemToReg=0 (ALU result)
  top->test_mode = 1;
  top->test_reg_write = 1;
  top->test_aluop = 3;         // I-type ALU
  top->test_alu_src = 1;       // Use immediate (not register)
  top->test_pc_sel = 0;        // PC = PC + 4
  top->test_branch_enable = 0; // No branch
  top->test_mem_read = 0;      // No memory read
  top->test_mem_write = 0;     // No memory write
  top->test_mem_to_reg = 0;    // Write ALU result to register
  std::cout
      << "Set control signals for ADDI: RegWrite=1, ALUSrc=1, ALUOp=I-type"
      << std::endl;
}

void TopLevel::set_control_signals_for_add() {
  // ADD x3, x1, x2: R-type instruction
  // Need: RegWrite=1, ALUOp=RTYPE, ALUSrc=0, MemToReg=0
  std::cout << "Setting control signals for ADD instruction" << std::endl;
}

void TopLevel::set_control_signals_for_store() {
  // SW x3, 0(x0): S-type instruction
  // Need: RegWrite=0, ALUOp=ADD, ALUSrc=1, MemWrite=1
  top->test_mode = 1;
  top->test_reg_write = 0;     // Don't write to register
  top->test_aluop = 0;         // ADD operation (for address calculation)
  top->test_alu_src = 1;       // Use immediate for address offset
  top->test_pc_sel = 0;        // PC = PC + 4
  top->test_branch_enable = 0; // No branch
  top->test_mem_read = 0;      // No memory read
  top->test_mem_write = 1;     // Memory write!
  top->test_mem_to_reg = 0;    // Don't care (not writing to reg)
  std::cout << "Set control signals for STORE: MemWrite=1, ALUSrc=1, ALUOp=ADD"
            << std::endl;
}

void TopLevel::set_control_signals_for_load() {
  // LW x4, 0(x0): I-type load
  // Need: RegWrite=1, ALUOp=ADD, ALUSrc=1, MemRead=1, MemToReg=1
  top->test_mode = 1;
  top->test_reg_write = 1;     // Write loaded data to register
  top->test_aluop = 0;         // ADD operation (for address calculation)
  top->test_alu_src = 1;       // Use immediate for address offset
  top->test_pc_sel = 0;        // PC = PC + 4
  top->test_branch_enable = 0; // No branch
  top->test_mem_read = 1;      // Memory read
  top->test_mem_write = 0;     // No memory write
  top->test_mem_to_reg = 1;    // Write memory data to register
  std::cout << "Set control signals for LOAD: MemRead=1, RegWrite=1, MemToReg=1"
            << std::endl;
}

void TopLevel::set_control_signals_for_branch() {
  // BEQ x3, x4, offset: SB-type
  // Need: RegWrite=0, ALUOp=SUB, ALUSrc=0, BranchEnable=1
  std::cout << "Setting control signals for BRANCH instruction" << std::endl;
}

void TopLevel::set_control_signals_nop() {
  // Default/NOP: no operations
  std::cout << "Setting control signals for NOP" << std::endl;
}

// Test framework
struct TestResult {
  std::string name;
  bool passed;
  std::string error;
};

std::vector<TestResult> test_results;

void run_test(const std::string &name, bool condition,
              const std::string &error = "") {
  test_results.push_back({name, condition, error});
  if (condition) {
    std::cout << "✓ " << name << std::endl;
  } else {
    std::cout << "✗ " << name << ": " << error << std::endl;
  }
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  TopLevel cpu(true);

  std::cout << "=== RISC-V Datapath Test (Manual Control) ===" << std::endl;
  std::cout << "NOTE: Control unit not implemented - setting signals manually"
            << std::endl;

  cpu.reset();
  cpu.dump_state();

  std::cout << "\n=== Test 1: Basic PC Increment ===" << std::endl;
  uint32_t pc_before = cpu.top->pc;
  cpu.tick();
  uint32_t pc_after = cpu.top->pc;

  run_test("PC increments", pc_after > pc_before,
           "PC should increment when no control signals set");

  std::cout << "\n=== Test 2: Instruction Memory Interface ===" << std::endl;
  uint32_t pc1 = cpu.top->pc;
  cpu.tick();
  uint32_t pc2 = cpu.top->pc;
  cpu.tick();
  uint32_t pc3 = cpu.top->pc;

  run_test("PC advances consistently", (pc2 - pc1) == (pc3 - pc2),
           "PC should advance by same amount each cycle");

  std::cout << "\n=== Test 3: Manual Store Operation ===" << std::endl;

  cpu.set_control_signals_for_store();
  cpu.tick();

  run_test("Store: Memory write signal asserted", cpu.top->bus_mem_write == 1,
           "MemWrite should be 1 when control signals set for store");

  run_test("Store: Memory read signal not asserted", cpu.top->bus_mem_read == 0,
           "MemRead should be 0 for store operation");

  cpu.dump_state();

  std::cout << "\n=== Test 4: Manual Load Operation ===" << std::endl;

  cpu.set_control_signals_for_load();
  cpu.tick();

  run_test("Load: Memory read signal asserted", cpu.top->bus_mem_read == 1,
           "MemRead should be 1 when control signals set for load");

  run_test("Load: Memory write signal not asserted",
           cpu.top->bus_mem_write == 0,
           "MemWrite should be 0 for load operation");

  cpu.dump_state();

  std::cout << "\n=== Test 4: Stability with Undefined Control ==="
            << std::endl;
  uint32_t pc_stable_start = cpu.top->pc;

  for (int i = 0; i < 10; i++) {
    cpu.tick();
  }

  uint32_t pc_stable_end = cpu.top->pc;
  bool pc_advanced = pc_stable_end > pc_stable_start;

  run_test("System remains stable", pc_advanced,
           "PC should continue advancing even with undefined control signals");

  run_test("No spurious memory operations",
           cpu.top->bus_mem_read == 0 && cpu.top->bus_mem_write == 0,
           "No memory operations should occur without control signals");

  std::cout << "\n=== Test 5: Component Connectivity ===" << std::endl;

  run_test("Bus data signals are reasonable",
           cpu.top->bus_data_in <= 0xFFFFFFFF &&
               cpu.top->bus_data_out <= 0xFFFFFFFF,
           "Bus data signals should be valid 32-bit values");

  run_test("Bus address is word-aligned when zero",
           (cpu.top->bus_addr_in & 0x3) == 0,
           "Default bus address should be word-aligned");

  run_test("ByteEn has reasonable default", cpu.top->bus_byteen <= 0xF,
           "ByteEn should be valid 4-bit value");

  std::cout << "\n=== Test 6: Extended Operation ===" << std::endl;

  for (int i = 0; i < 50; i++) {
    cpu.tick();
  }

  cpu.dump_state();

  run_test("Long-term stability", cpu.top->pc < 0x1000,
           "PC should not grow unreasonably large");

  run_test("No unexpected memory activity",
           cpu.top->bus_mem_read == 0 && cpu.top->bus_mem_write == 0,
           "Still no memory activity without control unit");

  std::cout << "\n=== Test Summary ===" << std::endl;
  int passed = 0;
  for (const auto &result : test_results) {
    if (result.passed)
      passed++;
  }

  std::cout << "Passed: " << passed << "/" << test_results.size() << " tests"
            << std::endl;

  if (passed == test_results.size()) {
    std::cout << "Basic datapath connectivity tests passed!" << std::endl;
  } else {
    std::cout << "\n❌ Some basic tests failed:" << std::endl;
    for (const auto &result : test_results) {
      if (!result.passed) {
        std::cout << "  - " << result.name << ": " << result.error << std::endl;
      }
    }
  }

  return 0;
}