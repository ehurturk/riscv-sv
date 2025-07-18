#include "../obj_dir/Vimem.h"
#include <string>
#include <verilated.h>
#include <verilated_vcd_c.h>

#include <iomanip>
#include <iostream>
#include <string.h>
#include <vector>

class IMEM {
private:
  Vimem *imem;

public:
  IMEM();
  ~IMEM();

  int load_data(int word_address);
  void debug_memory();
};

IMEM::IMEM() {
  imem = new Vimem;

  // Initialize
  imem->clk = 0;
  imem->eval();
}

IMEM::~IMEM() { delete imem; }

int IMEM::load_data(int pc) {
  imem->address_in = pc >> 2; // word address the pc
  imem->eval();

  return imem->instruction_data_out;
}

static int test_passed = 0;
static int total_tests = 0;

struct test_failure {
  std::string name;
  unsigned int exp;
  unsigned int act;
};

std::vector<test_failure> failures;

void run_test(const std::string &name, unsigned int exp, unsigned int act) {
  total_tests++;
  if (exp == act) {
    test_passed++;
    std::cout << "✓ " << name << std::endl;
  } else {
    failures.push_back({name, exp, act});
    std::cout << "✗ " << name << std::endl;
  }
}

/*
 * Test program initial load
 */
int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  IMEM mem;

  unsigned int i1 = mem.load_data(0x0); // 0x0 -> 0b000
  unsigned int i2 = mem.load_data(0x4); // 0x4 -> 0b001
  unsigned int i3 = mem.load_data(0x8); // 0x8 -> 0b010
  unsigned int i4 = mem.load_data(0xc); // 0xC -> 0b011

  run_test("1st instruction (addi x1, x0, 5)", 0x00500093, i1);
  run_test("2nd instruction (addi x2, x0, 10)", 0x00a00113, i2);
  run_test("3rd instruction (add x3, x1, x2)", 0x002081b3, i3);
  run_test("4th instruction (sw x3, 0(x0))", 0x00302023, i4);

  std::cout << "\n==== TEST SUMMARY ====" << std::endl;
  std::cout << "Passed " << test_passed << "/" << total_tests << " tests."
            << std::endl;

  if (failures.size() > 0) {
    std::cout << "\nTests failed:" << std::endl;
    for (const auto &failure : failures) {
      std::cout << failure.name << ":" << std::endl;
      std::cout << "\tExpected: 0x" << std::hex << std::setfill('0')
                << std::setw(8) << failure.exp << " | Got: 0x"
                << std::setfill('0') << std::setw(8) << failure.act
                << std::endl;
      std::cout << std::dec; // reset to dec
    }
  } else {
    std::cout << "All tests passed!" << std::endl;
  }

  return 0;
}