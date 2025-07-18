#include "Vtop.h"
#include <iomanip>
#include <iostream>
#include <unique_ptr>
#include <verilated.h>
#include <verilated_vcd_c.h>

class TopLevel {

public:
  TopLevel();
  ~TopLevel();

private:
  std::unique_ptr<Vtop> top;
};

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);

  Vtop *top = new Vtop;

  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;

  top->trace(tfp, 99);
  top->open("top.vcd");

  // Cleanup
  tfp->close();

  delete top;
  delete tfp;

  return 0;
}
