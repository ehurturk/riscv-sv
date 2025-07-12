#include "Vmux2.h"
#include "verilated.h"

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vmux2 *top = new Vmux2{contextp};

  top->d0 = 0x12;
  top->d1 = 0xDEADBEEF;
  top->signal = 1;

  for (int cycle = 0; cycle < 4; cycle++) {
    top->eval();
    top->signal = !top->signal;
    printf("Value: %u\n", top->out);
  }

  delete top;
  delete contextp;
  return 0;
}
