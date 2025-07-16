#include "Vdmem_top.h"
#include <iomanip>
#include <iostream>
#include <vector>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 500
vluint64_t sim_time = 0;

Vdmem_top *dut;
VerilatedVcdC *tfp;

void clock_cycle() {
  dut->clk = 0;
  dut->eval();
  tfp->dump(sim_time++);

  dut->clk = 1;
  dut->eval();
  tfp->dump(sim_time++);

  dut->clk = 0;
  dut->eval();
  tfp->dump(sim_time++);
}

void store(uint32_t addr, uint32_t data, uint8_t func3) {
  dut->mem_read = 0;
  dut->mem_write = 1;
  dut->func3 = func3;
  dut->address_in = addr;
  dut->data_in = data;
  dut->eval();
  clock_cycle();
  dut->mem_write = 0;
  dut->eval();
}

uint32_t load(uint32_t addr, uint8_t func3) {
  dut->mem_write = 0;
  dut->mem_read = 1;
  dut->func3 = func3;
  dut->address_in = addr;
  dut->eval();
  clock_cycle();
  dut->mem_read = 0;
  dut->eval();
  return dut->data_out;
}

struct TestResult {
  std::string name;
  bool passed;
};

std::vector<TestResult> results;

void run_test(const std::string &name, bool condition) {
  results.push_back({name, condition});
  std::cout << name << ": " << (condition ? "PASSED" : "FAILED") << std::endl;
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  dut = new Vdmem_top;

  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;
  dut->trace(tfp, 99);
  tfp->open("dmem_top.vcd");

  // Init signals
  dut->clk = 0;
  dut->mem_read = 0;
  dut->mem_write = 0;
  dut->func3 = 0;
  dut->address_in = 0;
  dut->data_in = 0;
  dut->eval();

  std::cout << "\n=== dmem_top Integration Tests ===\n" << std::endl;

  // === WORD STORE/LOAD ===
  std::cout << "Test 1: Word Store/Load" << std::endl;
  store(0, 0xCAFEBABE, 0b010);
  std::cout << "load(0, 0b010) == " << load(0,0b010) << std::endl;
  run_test("  lw at 0", load(0, 0b010) == 0xCAFEBABE);

  // === BYTE STORES ===
  std::cout << "\nTest 2: Byte Store/Load" << std::endl;
  store(4, 0x11, 0b000);
  store(5, 0x22, 0b000);
  store(6, 0x33, 0b000);
  store(7, 0x44, 0b000);
  run_test("  lb at 4", load(4, 0b000) == 0x11);
  run_test("  lb at 5", load(5, 0b000) == 0x22);
  run_test("  lb at 6", load(6, 0b000) == 0x33);
  run_test("  lb at 7", load(7, 0b000) == 0x44);
  run_test("  lw at 4", load(4, 0b010) == 0x44332211);

  // === SIGN EXTENSION TEST ===
  std::cout << "\nTest 3: Sign Extension" << std::endl;
  store(8, 0xFF, 0b000); // sb - store signed -1
  run_test("  lb (signed -1)", load(8, 0b000) == 0xFFFFFFFF);
  run_test("  lbu (unsigned 255)", load(8, 0b100) == 0x000000FF);

  // === HALFWORD ===
  std::cout << "\nTest 4: Halfword" << std::endl;
  store(12, 0xBEEF, 0b001); // sh
  store(14, 0xCAFE, 0b001); // sh
  run_test("  lh (signed)", load(12, 0b001) == 0xFFFFBEEF);
  run_test("  lhu (unsigned)", load(12, 0b101) == 0x0000BEEF);
  run_test("  lw combined", load(12, 0b010) == 0xCAFEBEEF);

  // === OVERWRITE ===
  std::cout << "\nTest 5: Overwrite Bytes" << std::endl;
  store(16, 0x12345678, 0b010); // sw
  store(17, 0xAB, 0b000);       // sb
  run_test("  lw after sb", load(16, 0b010) == 0x1234AB78);

  // === SUMMARY ===
  std::cout << "\n=== Test Summary ===" << std::endl;
  int passed = 0;
  for (const auto &t : results)
    if (t.passed)
      passed++;
  std::cout << "Passed " << passed << " / " << results.size() << std::endl;

  tfp->close();
  delete dut;
  delete tfp;
  return (passed == results.size()) ? 0 : 1;
}
