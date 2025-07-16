#include "Vdmem_bus.h"
#include "Vdmem_interface.h"
#include <iomanip>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

#define MAX_SIM_TIME 200
vluint64_t sim_time = 0;

void print_test(const char *test_name, bool passed) {
  std::cout << test_name << ": " << (passed ? "PASSED" : "FAILED") << std::endl;
}

bool check_value(uint32_t expected, uint32_t actual, const char *test_name) {
  bool passed = (expected == actual);
  std::cout << test_name << ": ";
  std::cout << "Expected=0x" << std::hex << std::setw(8) << std::setfill('0')
            << expected;
  std::cout << ", Actual=0x" << std::hex << std::setw(8) << std::setfill('0')
            << actual;
  std::cout << " - " << (passed ? "PASSED" : "FAILED") << std::endl;
  return passed;
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  Vdmem_interface *dut_interface = new Vdmem_interface;
  Vdmem_bus *dut_bus = new Vdmem_bus;

  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;

  dut_interface->trace(tfp, 99);
  tfp->open("dmem_interface.vcd");

  dut_interface->clk = 0;
  dut_interface->mem_read = 0;
  dut_interface->mem_write = 0;
  dut_bus->clk = 0;
  dut_bus->mem_read = 0;
  dut_bus->mem_write = 0;

  std::cout << "\n=== Data Memory Interface Tests ===\n" << std::endl;

  std::cout << "Test 1: Store Word (sw x1, 0(x0)) where x1 = 0xDEADBEEF"
            << std::endl;
  dut_interface->func3 = 0b010; // sw
  dut_interface->address_in = 0;
  dut_interface->data_in = 0xDEADBEEF;
  dut_interface->mem_write = 1;
  dut_interface->eval();

  check_value(0xDEADBEEF, dut_interface->bus_data_in, "Bus data");
  check_value(0b1111, dut_interface->bus_byteen, "Byte enable");

  dut_bus->addr_in = dut_interface->bus_addr;
  dut_bus->data_in = dut_interface->bus_data_in;
  dut_bus->byteen = dut_interface->bus_byteen;
  dut_bus->mem_write = 1;
  dut_bus->clk = 0;
  dut_bus->eval();
  dut_bus->clk = 1;
  dut_bus->eval();
  dut_bus->clk = 0;
  dut_bus->eval();
  dut_bus->mem_write = 0;

  // Test 2: Load Word (lw)
  std::cout << "\nTest 2: Load Word (lw x2, 0(x0))" << std::endl;
  dut_interface->mem_write = 0;
  dut_interface->mem_read = 1;
  dut_interface->func3 = 0b010;             // lw
  dut_interface->bus_data_out = 0xDEADBEEF; // Simulate bus response
  dut_interface->eval();

  check_value(0xDEADBEEF, dut_interface->data_out, "Loaded word");

  // Test 3: Store Byte (sb) at unaligned address
  std::cout << "\nTest 3: Store Byte (sb x1, 5(x0)) where x1 = 0xAB"
            << std::endl;
  dut_interface->mem_read = 0;
  dut_interface->mem_write = 1;
  dut_interface->func3 = 0b000;  // sb
  dut_interface->address_in = 5; // Byte offset = 1
  dut_interface->data_in = 0xAB;
  dut_interface->eval();

  check_value(0x0000AB00, dut_interface->bus_data_in, "Shifted data");
  check_value(0b0010, dut_interface->bus_byteen, "Byte enable");

  // Test 4: Load Byte Signed (lb)
  std::cout << "\nTest 4: Load Byte Signed (lb x2, 5(x0)) - negative value"
            << std::endl;
  dut_interface->mem_write = 0;
  dut_interface->mem_read = 1;
  dut_interface->func3 = 0b000; // lb (signed)
  dut_interface->address_in = 5;
  dut_interface->bus_data_out = 0x00AB0000; // AB in byte position 1
  dut_interface->eval();

  check_value(0xFFFFFFAB, dut_interface->data_out, "Sign-extended byte");

  // Test 5: Load Byte Unsigned (lbu)
  std::cout << "\nTest 5: Load Byte Unsigned (lbu x2, 5(x0))" << std::endl;
  dut_interface->func3 = 0b100; // lbu (unsigned)
  dut_interface->eval();

  check_value(0x000000AB, dut_interface->data_out, "Zero-extended byte");

  // Test 6: Store Halfword (sh)
  std::cout << "\nTest 6: Store Halfword (sh x1, 6(x0)) where x1 = 0x1234"
            << std::endl;
  dut_interface->mem_read = 0;
  dut_interface->mem_write = 1;
  dut_interface->func3 = 0b001;  // sh
  dut_interface->address_in = 6; // Byte offset = 2
  dut_interface->data_in = 0x1234;
  dut_interface->eval();

  check_value(0x12340000, dut_interface->bus_data_in, "Shifted halfword");
  check_value(0b1100, dut_interface->bus_byteen, "Byte enable");

  // Test 7: Load Halfword Signed (lh)
  std::cout << "\nTest 7: Load Halfword Signed (lh x2, 6(x0)) - negative value"
            << std::endl;
  dut_interface->mem_write = 0;
  dut_interface->mem_read = 1;
  dut_interface->func3 = 0b001; // lh (signed)
  dut_interface->address_in = 6;
  dut_interface->bus_data_out = 0x82340000; // 0x8234 in upper halfword
  dut_interface->eval();

  check_value(0xFFFF8234, dut_interface->data_out, "Sign-extended halfword");

  // Test 8: Load Halfword Unsigned (lhu)
  std::cout << "\nTest 8: Load Halfword Unsigned (lhu x2, 6(x0))" << std::endl;
  dut_interface->func3 = 0b101; // lhu (unsigned)
  dut_interface->eval();

  check_value(0x00008234, dut_interface->data_out, "Zero-extended halfword");

  // Test 9: Byte operations at all offsets
  std::cout << "\nTest 9: Byte operations at all offsets" << std::endl;
  for (int offset = 0; offset < 4; offset++) {
    dut_interface->mem_write = 1;
    dut_interface->mem_read = 0;
    dut_interface->func3 = 0b000; // sb
    dut_interface->address_in = offset;
    dut_interface->data_in = 0x55;
    dut_interface->eval();

    std::cout << "  Offset " << offset << ": ";
    std::cout << "byteen=0b" << std::bitset<4>(dut_interface->bus_byteen);
    std::cout << ", shifted_data=0x" << std::hex << dut_interface->bus_data_in
              << std::endl;
  }

  // Cleanup
  tfp->close();
  delete dut_interface;
  delete dut_bus;
  delete tfp;

  return 0;
}