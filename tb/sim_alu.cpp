#include "Valu.h"
#include "verilated.h"

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Valu *top = new Valu{contextp};

  top->op = 0x1;
  top->opA = 0x45;
  top->opB = 0x50;
  
  top->eval();

  printf("%d\n", top->out);

  delete top;
  delete contextp;
  return 0;
}
