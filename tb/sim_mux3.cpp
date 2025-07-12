#include "Vmux3.h"
#include "verilated.h"

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vregfile *top = new Vregfile{contextp};

  top->d0 = 0xDEADBEEF;
  top->d1 = 0x12;

  delete top;
  delete contextp;
  return 0;
}
