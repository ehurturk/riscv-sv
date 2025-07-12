#include "Vregfile.h"
#include "verilated.h"

int main(int argc, char **argv) {
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vregfile *top = new Vregfile{contextp};

    // Reset values
    top->clk = 0;
    top->write_enable = 0;
    top->r_reg1 = 0;
    top->r_reg2 = 0;
    top->w_reg = 0;
    top->w_data = 0;

    // Clock cycles
    for (int cycle = 0; cycle < 10; ++cycle) {
        top->clk = 1;

        if (cycle % 3 == 0) {
            top->write_enable = 1;
            top->w_reg = 5;
            top->w_data = cycle;
        }

        top->eval();

        top->clk = 0;
        top->eval();

        if (cycle % 3 == 1) {
            top->r_reg1 = 5;
            top->r_reg2 = 0;
            top->write_enable = 0;
        }

        if (cycle % 3 == 2) {
            printf("Read reg 5: %u\n", top->r_data1); 
        }
    }

    delete top;
    delete contextp;
    return 0;
}