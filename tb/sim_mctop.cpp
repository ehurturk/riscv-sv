#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);

  Vtop *top = new Vtop;
  VerilatedVcdC *tfp = new VerilatedVcdC;

  top->trace(tfp, 99);
  tfp->open("waveform.vcd");

  // Time simulation
  vluint64_t main_time = 0;

  // Clock and reset
  top->clk = 0;
  top->reset = 1;

  // Reset pulse for few cycles
  for (int i = 0; i < 10; ++i) {
    top->clk = !top->clk;
    top->eval();
    tfp->dump(main_time++);
  }

  top->reset = 0;

  // Run simulation until manual cutoff or halt signal (optional)
  for (int i = 0; i < 1000; ++i) {
    top->clk = !top->clk;
    top->eval();
    tfp->dump(main_time++);

    // Optional: print debug info
    if (top->clk) {
      printf("PC: 0x%08x, IR: 0x%08x, MemWrite: %d, Addr: 0x%08x, DataOut: "
             "0x%08x\n",
             top->pc, top->ir, top->bus_mem_write, top->bus_addr_in,
             top->bus_data_out);
    }

    // Optional: stop if a specific instruction/memory address is hit
    // if (top->pc == 0xDEADBEEF) break;
  }

  // Final cleanup
  tfp->close();
  top->final();
  delete tfp;
  delete top;

  return 0;
}
