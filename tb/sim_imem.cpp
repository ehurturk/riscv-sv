#include "Vimem_bus.h"
#include <fstream>
#include <iomanip>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 100
vluint64_t sim_time = 0;

// Create a test program file
void create_test_program() {
  std::ofstream prog("test_program.hex");

  // Simple test program with various RISC-V instructions
  prog << "00000013" << std::endl; // nop (addi x0, x0, 0)
  prog << "00500113" << std::endl; // addi x2, x0, 5
  prog << "00A00193" << std::endl; // addi x3, x0, 10
  prog << "003101B3" << std::endl; // add x3, x2, x3
  prog << "40310233" << std::endl; // sub x4, x2, x3
  prog << "00312023" << std::endl; // sw x3, 0(x2)
  prog << "00012283" << std::endl; // lw x5, 0(x2)
  prog << "00628663" << std::endl; // beq x5, x6, 12
  prog << "00008067" << std::endl; // ret (jalr x0, x1, 0)

  prog.close();
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  // Create test program
  create_test_program();

  // Create DUT
  Vimem_bus *dut = new Vimem_bus;

  // Initialize trace
  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("imem.vcd");

  // Initialize signals
  dut->clk = 0;
  dut->pc = 0;

  std::cout << "\n=== Instruction Memory Tests ===\n" << std::endl;

  // Expected instructions
  uint32_t expected_instrs[] = {
      0x00000013, // nop
      0x00500113, // addi x2, x0, 5
      0x00A00193, // addi x3, x0, 10
      0x003101B3, // add x3, x2, x3
      0x40310233, // sub x4, x2, x3
      0x00312023, // sw x3, 0(x2)
      0x00012283, // lw x5, 0(x2)
      0x00628663, // beq x5, x6, 12
      0x00008067  // ret
  };

  // Test 1: Sequential instruction fetch
  std::cout << "Test 1: Sequential Instruction Fetch" << std::endl;
  std::cout << "PC    | Instruction | Expected    | Status" << std::endl;
  std::cout << "------|-------------|-------------|-------" << std::endl;

  bool all_passed = true;

  for (int i = 0; i < 9; i++) {
    dut->pc = i * 4; // PC increments by 4
    dut->eval();
    tfp->dump(sim_time++);

    std::cout << std::hex << std::setw(4) << std::setfill('0') << dut->pc
              << "  | ";
    std::cout << std::hex << std::setw(8) << std::setfill('0')
              << dut->instruction_data_out << "   | ";
    std::cout << std::hex << std::setw(8) << std::setfill('0')
              << expected_instrs[i] << "   | ";

    if (dut->instruction_data_out == expected_instrs[i]) {
      std::cout << "PASS" << std::endl;
    } else {
      std::cout << "FAIL" << std::endl;
      all_passed = false;
    }
  }

  // Test 2: Non-aligned access (should still work due to word alignment in
  // module)
  std::cout << "\nTest 2: Non-aligned PC (should align to word boundary)"
            << std::endl;

  dut->pc = 5; // Not word-aligned
  dut->eval();
  tfp->dump(sim_time++);

  // Should fetch from address 4 (word-aligned)
  std::cout << "PC=5 (aligned to 4): ";
  std::cout << "Fetched=0x" << std::hex << std::setw(8) << std::setfill('0')
            << dut->instruction_data_out;
  std::cout << ", Expected=0x" << std::hex << std::setw(8) << std::setfill('0')
            << expected_instrs[1];
  std::cout << " - "
            << (dut->instruction_data_out == expected_instrs[1] ? "PASS"
                                                                : "FAIL")
            << std::endl;

  // Test 3: Jump to different addresses
  std::cout << "\nTest 3: Random Access Pattern" << std::endl;

  int test_addrs[] = {16, 0, 24, 8, 32};
  for (int i = 0; i < 5; i++) {
    dut->pc = test_addrs[i];
    dut->eval();
    tfp->dump(sim_time++);

    int idx = test_addrs[i] / 4;
    std::cout << "PC=" << std::dec << test_addrs[i] << ": ";
    std::cout << "Fetched=0x" << std::hex << std::setw(8) << std::setfill('0')
              << dut->instruction_data_out;
    std::cout << ", Expected=0x" << std::hex << std::setw(8)
              << std::setfill('0') << expected_instrs[idx];
    std::cout << " - "
              << (dut->instruction_data_out == expected_instrs[idx] ? "PASS"
                                                                    : "FAIL")
              << std::endl;
  }

  // Test 4: Boundary test (near end of memory)
  std::cout << "\nTest 4: Memory Boundary Test" << std::endl;

  // Test near the end of 1024-word memory
  dut->pc = 4092; // Last valid word address (1023 * 4)
  dut->eval();
  tfp->dump(sim_time++);

  std::cout << "PC=4092 (last word): Instruction=0x" << std::hex
            << dut->instruction_data_out << std::endl;

  std::cout << "\n=== Test Summary ===" << std::endl;
  std::cout << "All sequential tests " << (all_passed ? "PASSED" : "FAILED")
            << std::endl;

  // Cleanup
  tfp->close();
  delete dut;
  delete tfp;

  return 0;
}