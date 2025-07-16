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
  // Setup signals for write
  dut->mem_read = 0;
  dut->mem_write = 1;
  dut->func3 = func3;
  dut->address_in = addr;
  dut->data_in = data;

  // Let combinational logic settle
  dut->eval();

  // Clock to perform the write
  clock_cycle();

  // Clear write signal
  dut->mem_write = 0;
  dut->eval();
}

uint32_t load(uint32_t addr, uint8_t func3) {
  // Setup signals for read
  dut->mem_write = 0;
  dut->mem_read = 1;
  dut->func3 = func3;
  dut->address_in = addr;

  // Let combinational logic settle and read the output
  dut->eval();
  uint32_t result = dut->data_out;

  // Clear read signal (optional, but good practice)
  dut->mem_read = 0;
  dut->eval();

  return result;
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

void print_debug(const std::string &msg, uint32_t addr, uint32_t expected,
                 uint32_t actual) {
  std::cout << "  DEBUG " << msg << ": addr=0x" << std::hex << addr
            << ", expected=0x" << expected << ", actual=0x" << actual
            << std::dec << std::endl;
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
  store(0, 0xCAFEBABE, 0b010);           // sw
  uint32_t word_result = load(0, 0b010); // lw
  print_debug("Word load", 0, 0xCAFEBABE, word_result);
  run_test("  lw at 0", word_result == 0xCAFEBABE);

  // === BYTE STORES ===
  std::cout << "\nTest 2: Byte Store/Load" << std::endl;
  store(4, 0x11, 0b000); // sb
  store(5, 0x22, 0b000); // sb
  store(6, 0x33, 0b000); // sb
  store(7, 0x44, 0b000); // sb

  uint32_t b0 = load(4, 0b000);
  uint32_t b1 = load(5, 0b000);
  uint32_t b2 = load(6, 0b000);
  uint32_t b3 = load(7, 0b000);

  print_debug("Byte 0", 4, 0x11, b0);
  print_debug("Byte 1", 5, 0x22, b1);
  print_debug("Byte 2", 6, 0x33, b2);
  print_debug("Byte 3", 7, 0x44, b3);

  run_test("  lb at 4", b0 == 0x11);
  run_test("  lb at 5", b1 == 0x22);
  run_test("  lb at 6", b2 == 0x33);
  run_test("  lb at 7", b3 == 0x44);

  uint32_t word_combined = load(4, 0b010);
  print_debug("Word combined", 4, 0x44332211, word_combined);
  run_test("  lw at 4", word_combined == 0x44332211);

  // === SIGN EXTENSION TEST ===
  std::cout << "\nTest 3: Sign Extension" << std::endl;
  store(8, 0xFF, 0b000); // sb - store byte 0xFF

  uint32_t signed_byte = load(8, 0b000);   // lb (signed)
  uint32_t unsigned_byte = load(8, 0b100); // lbu (unsigned)

  print_debug("Signed byte", 8, 0xFFFFFFFF, signed_byte);
  print_debug("Unsigned byte", 8, 0x000000FF, unsigned_byte);

  run_test("  lb (signed -1)", signed_byte == 0xFFFFFFFF);
  run_test("  lbu (unsigned 255)", unsigned_byte == 0x000000FF);

  // === HALFWORD ===
  std::cout << "\nTest 4: Halfword" << std::endl;
  store(12, 0xBEEF, 0b001); // sh
  store(14, 0xCAFE, 0b001); // sh

  uint32_t signed_hw = load(12, 0b001);   // lh (signed)
  uint32_t unsigned_hw = load(12, 0b101); // lhu (unsigned)
  uint32_t word_hw = load(12, 0b010);     // lw

  print_debug("Signed halfword", 12, 0xFFFFBEEF, signed_hw);
  print_debug("Unsigned halfword", 12, 0x0000BEEF, unsigned_hw);
  print_debug("Word", 12, 0xCAFEBEEF, word_hw);

  run_test("  lh (signed)", signed_hw == 0xFFFFBEEF);
  run_test("  lhu (unsigned)", unsigned_hw == 0x0000BEEF);
  run_test("  lw combined", word_hw == 0xCAFEBEEF);

  // === OVERWRITE ===
  std::cout << "\nTest 5: Overwrite Bytes" << std::endl;
  store(16, 0x12345678, 0b010); // sw
  store(17, 0xAB, 0b000);       // sb at offset 1

  uint32_t overwrite_result = load(16, 0b010);
  print_debug("After overwrite", 16, 0x1234AB78, overwrite_result);
  run_test("  lw after sb", overwrite_result == 0x1234AB78);

  // === ADDITIONAL DEBUG TEST ===
  std::cout << "\nDebug: Simple byte test" << std::endl;
  store(20, 0x55, 0b000);                 // Store byte
  uint32_t simple_load = load(20, 0b100); // Load unsigned byte
  print_debug("Simple byte", 20, 0x55, simple_load);

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