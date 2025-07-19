// Single Cycle Control Unit Testbench

#include "Vsccontrol.h"
#include <cstddef>
#include <cstdint>
#include <iomanip>
#include <iostream>
#include <stdint.h>
#include <verilated.h>
#include <verilated_vcd_c.h>

struct InstructionInfo {
  uint8_t opcode;
  uint8_t rd, rs1, rs2;
  int32_t immediate;
  uint8_t func3, func7;
};

void decode_instr(uint32_t instruction, InstructionInfo &inf) {
  inf.opcode = instruction & 0x7F;
  inf.rd = (instruction >> 7) & 0x1F;
  inf.rs1 = (instruction >> 15) & 0x1F;
  inf.rs2 = (instruction >> 20) & 0x1F;
  inf.func3 = (instruction >> 12) & 0x7;
  inf.func7 = (instruction >> 25) & 0x7F;
}

class ControlUnit {
public:
    ControlUnit(bool gen_waveform = false);
    ~ControlUnit();

    void dump_signals();
    void test_instruction(uint32_t instruction);

    Vsccontrol *ctl;
private:
    VerilatedVcdC *tfp;

    unsigned int test_count;
};

ControlUnit::ControlUnit(bool gen_waveform): ctl(new Vsccontrol), tfp(NULL), test_count(0) {
    if (gen_waveform) {
        Verilated::traceEverOn(true);
        tfp = new VerilatedVcdC;
        ctl->trace(tfp, 99);
        tfp->open("control_unit.vcd");
    }
}

ControlUnit::~ControlUnit() {
    if (tfp) {
        tfp->close();
        delete tfp;
    }
    delete ctl;
}

void ControlUnit::dump_signals() {
  std::cout << "Control Signals:" << std::endl;
  std::cout << "\tRegWrite: " << (int)ctl->CTL_RegWrite << std::endl;
  std::cout << "\tAluOp: " << (int)ctl->CTL_AluOp << std::endl;
  std::cout << "\tAluSrc: " << (int)ctl->CTL_AluSrc << std::endl;
  std::cout << "\tPcSel: " << (int)ctl->CTL_PcSel << std::endl;
  std::cout << "\tBranchEnable: " << (int)ctl->CTL_BranchEnable << std::endl;
  std::cout << "\tMemRead: " << (int)ctl->CTL_MemRead << std::endl;
  std::cout << "\tMemWrite: " << (int)ctl->CTL_MemWrite << std::endl;
  std::cout << "\tMemToReg: " << (int)ctl->CTL_MemToReg << std::endl;
}

void ControlUnit::test_instruction(uint32_t instruction) {
    InstructionInfo instr;
    decode_instr(instruction, instr);

    ctl->inst_opc = instr.opcode;
    ctl->take_branch = true;

    ctl->eval();

    std::cout << "Instruction: 0x" << std::hex << std::setfill('0')
              << std::setw(8) << instruction << std::dec << std::endl;
    std::cout << "Opcode: " << instr.opcode << std::endl;
    dump_signals();

    if (tfp) {
      tfp->dump(++test_count);
    }
}

static uint32_t prg1[] = {
    0xff010113,
    0x00112623,
    0x00812423,
    0x00912223,
    0x00a12023,
    0x00100293,
    0x02a2d263,
    0x00050413,
    0xfff40513,
    0xfddff0ef,
    0x00050493,
    0xffe40513,
    0xfd1ff0ef,
    0x00950533,
    0x0080006f,
    0x00100513,
    0x00c12083,
    0x00812403,
    0x00412483,
    0x01010113,
    0x00008067
};

static uint32_t prg2[] = {
    0x00500293, // addi -> 111100000000
    0x00328313, // addi -> 111100000000
    0x100103b7, // lui  -> 1xxx00000011
    0x0063a023  // sw   -> 000100001xxx
};

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    ControlUnit ctl;

    for (const auto& instr : prg2) {
        ctl.test_instruction(instr);
    }
}
