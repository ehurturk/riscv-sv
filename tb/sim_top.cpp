#include "Vtop.h"
#include <cstddef>
#include <iomanip>
#include <iostream>
#include <map>
#include <string>
#include <vector>
#include <verilated.h>
#include <verilated_vcd_c.h>

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  // Initialize Verilator
  Vtop *top = new Vtop;

  // Enable waveform generation
  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  top->trace(tfp, 99);
  tfp->open("fibonacci.vcd");

  int sim_time = 0;


  // Reset
  top->reset = 1;
  top->clk = 0;
  top->eval();
  tfp->dump(sim_time++);
  top->clk = 1;
  top->eval();
  tfp->dump(sim_time++);

  top->reset = 0;
  top->clk = 0;
  top->eval();
  tfp->dump(sim_time++);
  top->clk = 1;
  top->eval();
  tfp->dump(sim_time++);

  std::cout << "Reset complete. Starting PC: 0x" << std::hex << top->pc
            << std::dec << "\n"
            << std::endl;

  std::map<uint32_t, uint32_t> memory_writes;

  int cycle = 0;
  int max_cycles = 200;
  bool done = false;
  uint32_t last_pc = 0;
  int stuck_count = 0;

  std::cout << "Running program..." << std::endl;
  std::cout << "Memory writes:" << std::endl;

  while (cycle < max_cycles && !done) {
    // Clock tick
    top->clk = 0;
    top->eval();
    tfp->dump(sim_time++);

    if (top->bus_mem_write && top->bus_byteen == 0xF) {
      memory_writes[top->bus_addr_in] = top->bus_data_in;
      std::cout << "  [" << std::setw(3) << cycle << "] mem[0x" << std::hex
                << top->bus_addr_in << "] = " << std::dec << top->bus_data_in
                << std::endl;
    }

    top->clk = 1;
    top->eval();
    tfp->dump(sim_time++);

    cycle++;

    if (top->pc == last_pc) {
      stuck_count++;
      if (stuck_count > 5) {
        done = true;
        std::cout << "\nProgram finished after " << cycle << " cycles"
                  << std::endl;
      }
    } else {
      stuck_count = 0;
      last_pc = top->pc;
    }
  }

  if (!done) {
    std::cout << "\nTimeout after " << max_cycles << " cycles!" << std::endl;
  }

  uint32_t expected[] = {0, 1, 1, 2, 3, 5, 8, 13, 21, 34};

  std::cout << "\n=== Results ===" << std::endl;
  std::cout << "Memory contents:" << std::endl;

  bool all_correct = true;
  for (int i = 0; i < 10; i++) {
    uint32_t addr = 0x100 + i * 4;
    uint32_t value = memory_writes[addr];
    bool correct = (value == expected[i]);

    std::cout << "  F(" << i << ") at 0x" << std::hex << addr << " = "
              << std::dec << value;

    if (correct) {
      std::cout << " ✓ " << std::endl;
    } else {
      std::cout << " x (expected " << expected[i] << ")" << std::endl;
      all_correct = false;
    }
  }

  // Verify results
  std::cout << "\n=== Verification ===" << std::endl;

  if (done && memory_writes.size() == 10 && all_correct) {
    std::cout << "SUCCESS: All tests passed!" << std::endl;
    std::cout << "\nThe Fibonacci sequence was correctly computed:"
              << std::endl;
    for (int i = 0; i < 10; i++) {
      std::cout << "  F(" << i << ") = " << memory_writes[0x100 + i * 4]
                << std::endl;
    }
  } else {
    std::cout << "FAILURE: Tests failed" << std::endl;
    if (!done)
      std::cout << "  - Program did not complete" << std::endl;
    if (memory_writes.size() != 10)
      std::cout << "  - Wrong number of memory writes" << std::endl;
    if (!all_correct)
      std::cout << "  - Incorrect values" << std::endl;
  }

  // Cleanup
  tfp->close();
  delete tfp;
  delete top;

  return all_correct ? 0 : 1;
}