#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <ctype.h>

#define MAX_LINE 256
#define MAX_LABELS 100
#define MAX_INSTRUCTIONS 1000

typedef struct {
    char name[32];
    uint32_t address;
} Label;

typedef struct {
    uint32_t instruction;
    uint32_t address;
} Instruction;

Label labels[MAX_LABELS];
Instruction instructions[MAX_INSTRUCTIONS];
int label_count = 0;
int instruction_count = 0;
uint32_t current_address = 0;

uint32_t get_register(char *reg) {
    if (reg[0] == 'x') {
        return atoi(reg + 1);
    }
    if (strcmp(reg, "zero") == 0) return 0;
    if (strcmp(reg, "ra") == 0) return 1;
    if (strcmp(reg, "sp") == 0) return 2;
    if (strcmp(reg, "gp") == 0) return 3;
    if (strcmp(reg, "tp") == 0) return 4;
    if (strcmp(reg, "t0") == 0) return 5;
    if (strcmp(reg, "t1") == 0) return 6;
    if (strcmp(reg, "t2") == 0) return 7;
    if (strcmp(reg, "s0") == 0 || strcmp(reg, "fp") == 0) return 8;
    if (strcmp(reg, "s1") == 0) return 9;
    if (strcmp(reg, "a0") == 0) return 10;
    if (strcmp(reg, "a1") == 0) return 11;
    if (strcmp(reg, "a2") == 0) return 12;
    if (strcmp(reg, "a3") == 0) return 13;
    if (strcmp(reg, "a4") == 0) return 14;
    if (strcmp(reg, "a5") == 0) return 15;
    if (strcmp(reg, "a6") == 0) return 16;
    if (strcmp(reg, "a7") == 0) return 17;
    if (strcmp(reg, "s2") == 0) return 18;
    if (strcmp(reg, "s3") == 0) return 19;
    if (strcmp(reg, "s4") == 0) return 20;
    if (strcmp(reg, "s5") == 0) return 21;
    if (strcmp(reg, "s6") == 0) return 22;
    if (strcmp(reg, "s7") == 0) return 23;
    if (strcmp(reg, "s8") == 0) return 24;
    if (strcmp(reg, "s9") == 0) return 25;
    if (strcmp(reg, "s10") == 0) return 26;
    if (strcmp(reg, "s11") == 0) return 27;
    if (strcmp(reg, "t3") == 0) return 28;
    if (strcmp(reg, "t4") == 0) return 29;
    if (strcmp(reg, "t5") == 0) return 30;
    if (strcmp(reg, "t6") == 0) return 31;
    return 0;
}

int32_t parse_immediate(char *imm) {
    if (imm[0] == '0' && imm[1] == 'x') {
        return (int32_t)strtol(imm, NULL, 16);
    }
    return (int32_t)strtol(imm, NULL, 10);
}

int find_label(char *name) {
    for (int i = 0; i < label_count; i++) {
        if (strcmp(labels[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

void add_label(char *name, uint32_t address) {
    strcpy(labels[label_count].name, name);
    labels[label_count].address = address;
    label_count++;
}

uint32_t encode_r_type(uint32_t opcode, uint32_t rd, uint32_t funct3, uint32_t rs1, uint32_t rs2, uint32_t funct7) {
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode;
}

uint32_t encode_i_type(uint32_t opcode, uint32_t rd, uint32_t funct3, uint32_t rs1, int32_t imm) {
    return ((imm & 0xfff) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode;
}

uint32_t encode_s_type(uint32_t opcode, uint32_t funct3, uint32_t rs1, uint32_t rs2, int32_t imm) {
    uint32_t imm_11_5 = (imm >> 5) & 0x7f;
    uint32_t imm_4_0 = imm & 0x1f;
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode;
}

uint32_t encode_b_type(uint32_t opcode, uint32_t funct3, uint32_t rs1, uint32_t rs2, int32_t imm) {
    uint32_t imm_12 = (imm >> 12) & 1;
    uint32_t imm_11 = (imm >> 11) & 1; 
    uint32_t imm_10_5 = (imm >> 5) & 0x3f;
    uint32_t imm_4_1 = (imm >> 1) & 0xf;
    return (imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | opcode;
}

uint32_t encode_u_type(uint32_t opcode, uint32_t rd, int32_t imm) {
    return (imm & 0xfffff000) | (rd << 7) | opcode;
}

uint32_t encode_j_type(uint32_t opcode, uint32_t rd, int32_t imm) {
    uint32_t imm_20 = (imm >> 20) & 1;
    uint32_t imm_19_12 = (imm >> 12) & 0xff;
    uint32_t imm_11 = (imm >> 11) & 1;
    uint32_t imm_10_1 = (imm >> 1) & 0x3ff;
    return (imm_20 << 31) | (imm_10_1 << 21) | (imm_11 << 20) | (imm_19_12 << 12) | (rd << 7) | opcode;
}

uint32_t assemble_instruction(char *line, uint32_t pc) {
    char *tokens[5];
    int token_count = 0;
    char *token = strtok(line, " \t,()");
    
    while (token && token_count < 5) {
        tokens[token_count++] = token;
        token = strtok(NULL, " \t,()");
    }
    
    if (token_count == 0) return 0;
    
    char *op = tokens[0];
    
    if (strcmp(op, "add") == 0) {
        return encode_r_type(0x33, get_register(tokens[1]), 0x0, get_register(tokens[2]), get_register(tokens[3]), 0x00);
    }
    if (strcmp(op, "sub") == 0) {
        return encode_r_type(0x33, get_register(tokens[1]), 0x0, get_register(tokens[2]), get_register(tokens[3]), 0x20);
    }
    if (strcmp(op, "xor") == 0) {
        return encode_r_type(0x33, get_register(tokens[1]), 0x4, get_register(tokens[2]), get_register(tokens[3]), 0x00);
    }
    if (strcmp(op, "or") == 0) {
        return encode_r_type(0x33, get_register(tokens[1]), 0x6, get_register(tokens[2]), get_register(tokens[3]), 0x00);
    }
    if (strcmp(op, "and") == 0) {
        return encode_r_type(0x33, get_register(tokens[1]), 0x7, get_register(tokens[2]), get_register(tokens[3]), 0x00);
    }
    if (strcmp(op, "sll") == 0) {
        return encode_r_type(0x33, get_register(tokens[1]), 0x1, get_register(tokens[2]), get_register(tokens[3]), 0x00);
    }
    if (strcmp(op, "srl") == 0) {
        return encode_r_type(0x33, get_register(tokens[1]), 0x5, get_register(tokens[2]), get_register(tokens[3]), 0x00);
    }
    if (strcmp(op, "sra") == 0) {
        return encode_r_type(0x33, get_register(tokens[1]), 0x5, get_register(tokens[2]), get_register(tokens[3]), 0x20);
    }
    if (strcmp(op, "slt") == 0) {
        return encode_r_type(0x33, get_register(tokens[1]), 0x2, get_register(tokens[2]), get_register(tokens[3]), 0x00);
    }
    if (strcmp(op, "sltu") == 0) {
        return encode_r_type(0x33, get_register(tokens[1]), 0x3, get_register(tokens[2]), get_register(tokens[3]), 0x00);
    }
    
    if (strcmp(op, "addi") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x0, get_register(tokens[2]), parse_immediate(tokens[3]));
    }
    if (strcmp(op, "xori") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x4, get_register(tokens[2]), parse_immediate(tokens[3]));
    }
    if (strcmp(op, "ori") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x6, get_register(tokens[2]), parse_immediate(tokens[3]));
    }
    if (strcmp(op, "andi") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x7, get_register(tokens[2]), parse_immediate(tokens[3]));
    }
    if (strcmp(op, "slli") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x1, get_register(tokens[2]), parse_immediate(tokens[3]));
    }
    if (strcmp(op, "srli") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x5, get_register(tokens[2]), parse_immediate(tokens[3]));
    }
    if (strcmp(op, "srai") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x5, get_register(tokens[2]), parse_immediate(tokens[3]) | 0x400);
    }
    if (strcmp(op, "slti") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x2, get_register(tokens[2]), parse_immediate(tokens[3]));
    }
    if (strcmp(op, "sltiu") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x3, get_register(tokens[2]), parse_immediate(tokens[3]));
    }
    
    if (strcmp(op, "lb") == 0) {
        return encode_i_type(0x03, get_register(tokens[1]), 0x0, get_register(tokens[3]), parse_immediate(tokens[2]));
    }
    if (strcmp(op, "lh") == 0) {
        return encode_i_type(0x03, get_register(tokens[1]), 0x1, get_register(tokens[3]), parse_immediate(tokens[2]));
    }
    if (strcmp(op, "lw") == 0) {
        return encode_i_type(0x03, get_register(tokens[1]), 0x2, get_register(tokens[3]), parse_immediate(tokens[2]));
    }
    if (strcmp(op, "lbu") == 0) {
        return encode_i_type(0x03, get_register(tokens[1]), 0x4, get_register(tokens[3]), parse_immediate(tokens[2]));
    }
    if (strcmp(op, "lhu") == 0) {
        return encode_i_type(0x03, get_register(tokens[1]), 0x5, get_register(tokens[3]), parse_immediate(tokens[2]));
    }
    
    if (strcmp(op, "sb") == 0) {
        return encode_s_type(0x23, 0x0, get_register(tokens[3]), get_register(tokens[1]), parse_immediate(tokens[2]));
    }
    if (strcmp(op, "sh") == 0) {
        return encode_s_type(0x23, 0x1, get_register(tokens[3]), get_register(tokens[1]), parse_immediate(tokens[2]));
    }
    if (strcmp(op, "sw") == 0) {
        return encode_s_type(0x23, 0x2, get_register(tokens[3]), get_register(tokens[1]), parse_immediate(tokens[2]));
    }
    
    if (strcmp(op, "beq") == 0) {
        int label_idx = find_label(tokens[3]);
        int32_t offset = (label_idx != -1) ? labels[label_idx].address - pc : 0;
        return encode_b_type(0x63, 0x0, get_register(tokens[1]), get_register(tokens[2]), offset);
    }
    if (strcmp(op, "bne") == 0) {
        int label_idx = find_label(tokens[3]);
        int32_t offset = (label_idx != -1) ? labels[label_idx].address - pc : 0;
        return encode_b_type(0x63, 0x1, get_register(tokens[1]), get_register(tokens[2]), offset);
    }
    if (strcmp(op, "blt") == 0) {
        int label_idx = find_label(tokens[3]);
        int32_t offset = (label_idx != -1) ? labels[label_idx].address - pc : 0;
        return encode_b_type(0x63, 0x4, get_register(tokens[1]), get_register(tokens[2]), offset);
    }
    if (strcmp(op, "bge") == 0) {
        int label_idx = find_label(tokens[3]);
        int32_t offset = (label_idx != -1) ? labels[label_idx].address - pc : 0;
        return encode_b_type(0x63, 0x5, get_register(tokens[1]), get_register(tokens[2]), offset);
    }
    if (strcmp(op, "bltu") == 0) {
        int label_idx = find_label(tokens[3]);
        int32_t offset = (label_idx != -1) ? labels[label_idx].address - pc : 0;
        return encode_b_type(0x63, 0x6, get_register(tokens[1]), get_register(tokens[2]), offset);
    }
    if (strcmp(op, "bgeu") == 0) {
        int label_idx = find_label(tokens[3]);
        int32_t offset = (label_idx != -1) ? labels[label_idx].address - pc : 0;
        return encode_b_type(0x63, 0x7, get_register(tokens[1]), get_register(tokens[2]), offset);
    }
    
    if (strcmp(op, "jal") == 0) {
        int label_idx = find_label(tokens[2]);
        int32_t offset = (label_idx != -1) ? labels[label_idx].address - pc : 0;
        return encode_j_type(0x6f, get_register(tokens[1]), offset);
    }
    if (strcmp(op, "jalr") == 0) {
        return encode_i_type(0x67, get_register(tokens[1]), 0x0, get_register(tokens[3]), parse_immediate(tokens[2]));
    }
    
    if (strcmp(op, "lui") == 0) {
        return encode_u_type(0x37, get_register(tokens[1]), parse_immediate(tokens[2]) << 12);
    }
    if (strcmp(op, "auipc") == 0) {
        return encode_u_type(0x17, get_register(tokens[1]), parse_immediate(tokens[2]) << 12);
    }
    
    if (strcmp(op, "li") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x0, 0, parse_immediate(tokens[2]));
    }
    if (strcmp(op, "mv") == 0) {
        return encode_i_type(0x13, get_register(tokens[1]), 0x0, get_register(tokens[2]), 0);
    }
    if (strcmp(op, "nop") == 0) {
        return encode_i_type(0x13, 0, 0x0, 0, 0);
    }
    if (strcmp(op, "j") == 0) {
        int label_idx = find_label(tokens[1]);
        int32_t offset = (label_idx != -1) ? labels[label_idx].address - pc : 0;
        return encode_j_type(0x6f, 0, offset);
    }
    if (strcmp(op, "jr") == 0) {
        return encode_i_type(0x67, 0, 0x0, get_register(tokens[1]), 0);
    }
    if (strcmp(op, "ret") == 0) {
        return encode_i_type(0x67, 0, 0x0, 1, 0);
    }
    if (strcmp(op, "beqz") == 0) {
        int label_idx = find_label(tokens[2]);
        int32_t offset = (label_idx != -1) ? labels[label_idx].address - pc : 0;
        return encode_b_type(0x63, 0x0, get_register(tokens[1]), 0, offset);
    }
    if (strcmp(op, "bnez") == 0) {
        int label_idx = find_label(tokens[2]);
        int32_t offset = (label_idx != -1) ? labels[label_idx].address - pc : 0;
        return encode_b_type(0x63, 0x1, get_register(tokens[1]), 0, offset);
    }
    
    return 0;
}

void first_pass(FILE *file) {
    char line[MAX_LINE];
    current_address = 0;
    
    while (fgets(line, sizeof(line), file)) {
        char *trimmed = line;
        while (isspace(*trimmed)) trimmed++;
        
        if (*trimmed == '\0' || *trimmed == '#' || *trimmed == '.') continue;
        
        char *colon = strchr(trimmed, ':');
        if (colon) {
            *colon = '\0';
            add_label(trimmed, current_address);
            continue;
        }
        
        current_address += 4;
    }
}

void second_pass(FILE *file) {
    char line[MAX_LINE];
    current_address = 0;
    
    while (fgets(line, sizeof(line), file)) {
        char *trimmed = line;
        while (isspace(*trimmed)) trimmed++;
        
        if (*trimmed == '\0' || *trimmed == '#' || *trimmed == '.') continue;
        
        char *colon = strchr(trimmed, ':');
        if (colon) {
            continue;
        }
        
        uint32_t inst = assemble_instruction(trimmed, current_address);
        instructions[instruction_count].instruction = inst;
        instructions[instruction_count].address = current_address;
        instruction_count++;
        current_address += 4;
    }
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <input.s> <output.hex>\n", argv[0]);
        return 1;
    }
    
    FILE *input = fopen(argv[1], "r");
    if (!input) {
        printf("Error: Cannot open input file %s\n", argv[1]);
        return 1;
    }
    
    first_pass(input);
    rewind(input);
    second_pass(input);
    fclose(input);
    
    FILE *output = fopen(argv[2], "w");
    if (!output) {
        printf("Error: Cannot open output file %s\n", argv[2]);
        return 1;
    }
    
    for (int i = 0; i < instruction_count; i++) {
        fprintf(output, "%08x\n", instructions[i].instruction);
    }
    
    fclose(output);
    printf("Assembled %d instructions\n", instruction_count);
    return 0;
}