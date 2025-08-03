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
  tfp->open("pipelined.vcd");

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

  std::cout << "Reset complete. Starting PC (IF): 0x" << std::hex << top->o_pc_if
            << std::dec << "\n"
            << std::endl;

  std::map<uint32_t, uint32_t> memory_writes;

  int cycle = 0;
  int max_cycles = 200;
  uint32_t last_pc_wb = 0;
  int stall_count = 0;

  while (cycle < max_cycles) {
    // Positive edge
    top->clk = 1;
    top->eval();
    tfp->dump(sim_time++);

    // Check for memory writes (from MEM stage)
    if (top->bus_mem_write && top->bus_byteen == 0xF) {
      memory_writes[top->bus_addr_in] = top->bus_data_in;
      std::cout << "MEM[0x" << std::hex << std::setfill('0') << std::setw(8)
                << top->bus_addr_in << "] = " << std::dec << top->bus_data_in
                << std::endl;
    }

    // Negative edge
    top->clk = 0;
    top->eval();
    tfp->dump(sim_time++);

    // Check for stalls (WB PC not changing)
    if (top->o_pc_wb == last_pc_wb && cycle > 5) {
      stall_count++;
      if (stall_count > 20) {
        std::cout << "Processor appears to be stalled. Stopping simulation."
                  << std::endl;
        break;
      }
    } else {
      stall_count = 0;
      last_pc_wb = top->o_pc_wb;
    }

    // Print pipeline state every 10 cycles for debugging
    if (cycle % 10 == 0) {
      std::cout << "Cycle " << cycle << ": IF=0x" << std::hex 
                << top->o_pc_if << " ID=0x" << top->o_pc_id 
                << " EX=0x" << top->o_pc_ex << " MEM=0x" << top->o_pc_mem
                << " WB=0x" << top->o_pc_wb << std::dec << std::endl;
    }

    cycle++;
  }

  std::cout << "\nSimulation completed after " << cycle << " cycles" << std::endl;
  std::cout << "Final pipeline state:" << std::endl;
  std::cout << "  IF  PC: 0x" << std::hex << top->o_pc_if << " Instr: 0x" << top->o_instruction_if << std::endl;
  std::cout << "  ID  PC: 0x" << std::hex << top->o_pc_id << " Instr: 0x" << top->o_instruction_id << std::endl;
  std::cout << "  EX  PC: 0x" << std::hex << top->o_pc_ex << " Instr: 0x" << top->o_instruction_ex << std::endl;
  std::cout << "  MEM PC: 0x" << std::hex << top->o_pc_mem << " Instr: 0x" << top->o_instruction_mem << std::endl;
  std::cout << "  WB  PC: 0x" << std::hex << top->o_pc_wb << " Instr: 0x" << top->o_instruction_wb << std::dec << std::endl;

  std::cout << "\nMemory writes:" << std::endl;
  for (const auto &write : memory_writes) {
    std::cout << "  [0x" << std::hex << write.first << "] = " << std::dec
              << write.second << std::endl;
  }

  tfp->close();
  delete top;
  delete tfp;

  return 0;
}