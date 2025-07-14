#include "Valu.h"
#include "verilated.h"
#include <bitset>
#include <stdint.h>

enum ALU_OPS {
  ALU_ADD = 0,
  ALU_SUB,
  ALU_AND,
  ALU_OR,
  ALU_XOR,
  ALU_SLL,
  ALU_SRL,
  ALU_SRA,
  ALU_SLT,
  ALU_SLTU
};

void print_flags(uint8_t flags) {
  printf("Flags (VNCZ): %d%d%d%d\n", (flags >> 3) & 1, (flags >> 2) & 1,
         (flags >> 1) & 1, (flags & 1));
}

void run_test(Valu *alu, uint32_t a, uint32_t b, uint8_t op,
              const char *opname) {
  alu->op = op;
  alu->opA = a;
  alu->opB = b;
  alu->eval();

  printf("=== %s ===\n", opname);
  printf("opA     = 0x%08X\n", a);
  printf("opB     = 0x%08X\n", b);
  printf("out     = 0x%08X\n", alu->out);
  print_flags(alu->flags_out);
  printf("\n");
}

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Valu *alu = new Valu{contextp};

  // ADD
  run_test(alu, 0x7FFFFFFF, 0x01, ALU_ADD, "ADD");

  // SUB
  run_test(alu, 0x00000010, 0x00000020, ALU_SUB, "SUB");

  // AND
  run_test(alu, 0xF0F0F0F0, 0x0F0F0F0F, ALU_AND, "AND");

  // OR
  run_test(alu, 0xF0000000, 0x0000000F, ALU_OR, "OR");

  // XOR
  run_test(alu, 0xAAAAAAAA, 0x55555555, ALU_XOR, "XOR");

  // SLL: 0x00000001 << 4 = 0x10
  run_test(alu, 0x00000001, 0x00000004, ALU_SLL, "SLL");

  // SRL
  run_test(alu, 0x80000000, 0x00000004, ALU_SRL, "SRL");

  // SRA
  run_test(alu, 0xF0000000, 0x00000004, ALU_SRA, "SRA");

  // SLT
  run_test(alu, 0xFFFFFFFF, 0x00000001, ALU_SLT, "SLT");

  // SLTU
  run_test(alu, 0x00000001, 0xFFFFFFFF, ALU_SLTU, "SLTU");

  delete alu;
  delete contextp;
  return 0;
}
