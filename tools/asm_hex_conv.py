import sys
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR)
file_path_asm = os.path.join(PROJECT_ROOT, "programs", "asm_instr.asm")
file_path_hex = os.path.join(PROJECT_ROOT, "programs", "hex_instr.hex")

max_instr_mem = 2048
max_data_mem = 0x0FFC

register_format_opcode = "000000"

instr_pseudo = ["INV", "NOP", "SUBI"]

instr_string = [
    "JMP", "JR", "JAL", "BEQ", "BNE",
    "LW", "SW", "LB", "LBU", "SB", "LH", "LHU", "SH",
    "LUI", "SLTI", "ADDI", "ANDI", "ORI", "XORI",
    "SLT", "ADD", "AND", "OR", "XOR", "SUB",
    "SLL", "SRL", "SRA", "MULLO", "MULHI"
]

reg_string = ["R0", "R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9", "R10", "R11", "R12", "R13", "R14", "R15"]

instr_bin = [
    "000001", "000010", "000011", "000100", "000101",
    "000110", "000111", "001000", "001001", "001010", "001011", "001100", "001101",
    "001110", "001111", "010000", "010001", "010010", "010011",
    "001111", "010000", "010001", "010010", "010011", "010100",
    "010101", "010110", "010111", "011000", "011001"
]

reg_bin = ["00000", "00001", "00010", "00011", "00100", "00101", "00110", "00111",
           "01000", "01001", "01010", "01011", "01100", "01101", "01110", "01111"]

asm_lines = []


def reg_bin_format(reg: str) -> str:
    if reg in reg_string:
        return reg_bin[reg_string.index(reg)]
    print("Error: Unknown Register Command.")
    sys.exit(1)


def instr_bin_format(opcode: str) -> str:
    if opcode in instr_string:
        return instr_bin[instr_string.index(opcode)]
    print("Error: Unknown Instruction Command.")
    sys.exit(1)


def instr_format(asm_instr: str) -> str:
    if asm_instr in ["JR", "SLT", "ADD", "AND", "OR", "XOR", "SUB", "SLL", "SRL", "SRA", "MULLO", "MULHI"]:
        return "Register"

    if asm_instr in ["JMP", "JAL"]:
        return "Jump"

    if asm_instr in ["BEQ", "BNE",
                     "LW", "SW", "LB", "LBU", "SB", "LH", "LHU", "SH",
                     "LUI", "SLTI", "ADDI", "ANDI", "ORI", "XORI"]:
        return "Immediate"

    print("Error: Unknown Instruction Command.")
    sys.exit(1)


def imm16_signed(n: int) -> str:
    if n < -32768 or n > 32767:
        print("Error: Signed immediate out of 16-bit range.")
        sys.exit(1)
    return format(n & 0xFFFF, "016b")


def imm16_unsigned(n: int) -> str:
    if n < 0 or n > 0xFFFF:
        print("Error: Unsigned immediate out of 16-bit range.")
        sys.exit(1)
    return format(n, "016b")


def enc_jump26_from_byteaddr(byte_addr: int) -> str:
    if byte_addr < 0 or (byte_addr % 4) != 0:
        print("Error: Jump target must be >=0 and word-aligned (multiple of 4).")
        sys.exit(1)
    word_addr = byte_addr >> 2
    if word_addr > ((1 << 26) - 1):
        print("Error: Jump target too large for 26-bit field.")
        sys.exit(1)
    return format(word_addr, "026b")


def parse_mem_operand(op_str: str):
    s = op_str.strip()

    if s.startswith("[") and s.endswith("]"):
        off = int(s[1:-1], 0)
        return ("R0", off, "ABS")

    if "(" in s and s.endswith(")"):
        off_str, rest = s.split("(", 1)
        base = rest[:-1].strip()
        off = int(off_str.strip(), 0) if off_str.strip() else 0
        return (base, off, "BASEOFF")

    print("Error: Bad memory operand. Use [addr] or offset(Rx).")
    sys.exit(1)


def reg_format(reg1, reg2, reg3, func_code):
    if func_code == "SLL" or func_code == "SRL" or func_code == "SRA":
        try:
            shamt = int(reg3, 0)
        except ValueError:
            print("Error: Shift amount must be a number.")
            sys.exit(1)
        if shamt < 0 or shamt > 31:
            print("Error: Shift amount must be 0..31.")
            sys.exit(1)
        return (
            register_format_opcode
            + "00000"
            + reg_bin_format(reg2)
            + reg_bin_format(reg1)
            + format(shamt, "05b")
            + instr_bin_format(func_code)
        )
    else:
        return (
            register_format_opcode
            + reg_bin_format(reg3)
            + reg_bin_format(reg2)
            + reg_bin_format(reg1)
            + "00000"
            + instr_bin_format(func_code)
        )


def immediate_format(op_code, rs, rt, imm16):
    return instr_bin_format(op_code) + reg_bin_format(rs) + reg_bin_format(rt) + imm16


def jump_format(op_code, target26):
    return instr_bin_format(op_code) + target26


def expand_pseudos(token_lines):
    out = []
    for parts in token_lines:
        if not parts:
            continue

        op = parts[0]

        if op == "NOP":
            out.append(["SLL", "R0", "R0", "0"])
            continue

        if op == "SUBI":
            if len(parts) != 4:
                print("Error: SUBI format: SUBI Rt Rs imm")
                sys.exit(1)
            rt = parts[1]
            rs = parts[2]
            try:
                imm = int(parts[3], 0)
            except ValueError:
                print("Error: SUBI immediate must be a number.")
                sys.exit(1)
            out.append(["ADDI", rt, rs, str(-imm)])
            continue

        if op == "INV":
            if len(parts) != 3:
                print("Error: INV format: INV Rd Rs")
                sys.exit(1)
            rd = parts[1]
            rs = parts[2]
            scratch = "R15"
            if rd == scratch or rs == scratch:
                print("Error: INV pseudo uses R15 as scratch; don't use R15 as rd/rs for INV.")
                sys.exit(1)

            out.append(["LUI", scratch, "0xFFFF"])
            out.append(["ORI", scratch, scratch, "0xFFFF"])
            out.append(["XOR", rd, rs, scratch])
            continue

        out.append(parts)

    return out


with open(file_path_asm, "r") as file:
    for line in file:
        stripped_line = line.strip()
        if stripped_line and (not stripped_line.startswith(";") and not stripped_line.startswith("#")):
            stripped_line = stripped_line.split(";")[0].strip()
            asm_lines.append(stripped_line)

token_lines = []
for line in asm_lines:
    clean_line = line.replace(",", "")
    token_lines.append(clean_line.split())

token_lines = expand_pseudos(token_lines)

if len(token_lines) > max_instr_mem:
    print("Error: Exceeded maximum instruction memory after pseudo expansion.")
    sys.exit(1)

hex_lines = []

for i, parts in enumerate(token_lines):
    asm_instr = parts[0]
    fmt = instr_format(asm_instr)

    if fmt == "Register":
        if asm_instr == "JR":
            if len(parts) != 2:
                print("Error: JR format: JR Rs")
                sys.exit(1)
            rs = parts[1]
            binary_string_instr = (
                register_format_opcode
                + reg_bin_format(rs)
                + "00000"
                + "00000"
                + "00000"
                + instr_bin_format("JR")
            )
        else:
            if len(parts) != 4:
                print("Error: Wrong number of arguments for Register format.")
                sys.exit(1)

            if asm_instr in ["SLL", "SRL", "SRA"]:
                reg1 = parts[1]
                reg2 = parts[2]
                shamt = parts[3]
                binary_string_instr = reg_format(reg1, reg2, shamt, asm_instr)
            else:
                reg1 = parts[1]
                reg2 = parts[3]
                reg3 = parts[2]
                binary_string_instr = reg_format(reg1, reg2, reg3, asm_instr)

    elif fmt == "Immediate":

        if asm_instr == "JR":
            if len(parts) != 2:
                print("Error: JR format: JR Rs")
                sys.exit(1)
            rs = parts[1]
            binary_string_instr = immediate_format("JR", rs, "R0", "0000000000000000")

        elif asm_instr == "LUI":
            if len(parts) != 3:
                print("Error: LUI format: LUI Rt imm")
                sys.exit(1)
            rt = parts[1]
            imm = int(parts[2], 0)
            imm16 = imm16_unsigned(imm)
            binary_string_instr = immediate_format("LUI", "R0", rt, imm16)

        elif asm_instr in ["LW", "SW", "LB", "LBU", "SB", "LH", "LHU", "SH"]:
            if len(parts) != 3:
                print(f"Error: {asm_instr} format: {asm_instr} Rt [addr]  OR  {asm_instr} Rt off(Rb)")
                sys.exit(1)

            rt = parts[1]
            base, off, mode = parse_mem_operand(parts[2])

            if asm_instr in ["LW", "SW"] and (off % 4 != 0):
                print("Error: LW/SW address must be word-aligned (multiple of 4).")
                sys.exit(1)
            if asm_instr in ["LH", "LHU", "SH"] and (off % 2 != 0):
                print("Error: LH/LHU/SH address must be halfword-aligned (multiple of 2).")
                sys.exit(1)

            if mode == "ABS":
                if off < 0 or off > max_data_mem:
                    print("Error: Data memory absolute address out of range.")
                    sys.exit(1)
                imm16 = imm16_unsigned(off)
            else:
                imm16 = imm16_signed(off)

            binary_string_instr = immediate_format(asm_instr, base, rt, imm16)

        elif asm_instr in ["BEQ", "BNE"]:
            if len(parts) != 4:
                print(f"Error: {asm_instr} format: {asm_instr} Rs Rt target_byte_addr")
                sys.exit(1)

            rs = parts[1]
            rt = parts[2]
            target_byte = int(parts[3], 0)

            if target_byte < 0 or (target_byte % 4) != 0:
                print("Error: Branch target must be >=0 and word-aligned (multiple of 4).")
                sys.exit(1)

            word_addr = target_byte >> 2
            imm16 = imm16_unsigned(word_addr)
            binary_string_instr = immediate_format(asm_instr, rs, rt, imm16)

        elif asm_instr in ["ADDI", "SLTI"]:
            if len(parts) != 4:
                print(f"Error: {asm_instr} format: {asm_instr} Rt Rs imm")
                sys.exit(1)
            rt = parts[1]
            rs = parts[2]
            imm = int(parts[3], 0)
            imm16 = imm16_signed(imm)
            binary_string_instr = immediate_format(asm_instr, rs, rt, imm16)

        elif asm_instr in ["ANDI", "ORI", "XORI"]:
            if len(parts) != 4:
                print(f"Error: {asm_instr} format: {asm_instr} Rt Rs imm")
                sys.exit(1)
            rt = parts[1]
            rs = parts[2]
            imm = int(parts[3], 0)
            imm16 = imm16_unsigned(imm)
            binary_string_instr = immediate_format(asm_instr, rs, rt, imm16)

        else:
            print("Error: Immediate instruction not handled.")
            sys.exit(1)

    elif fmt == "Jump":
        if len(parts) != 2:
            print(f"Error: {asm_instr} format: {asm_instr} target_byte_addr")
            sys.exit(1)

        target_byte = int(parts[1], 0)
        target26 = enc_jump26_from_byteaddr(target_byte)
        binary_string_instr = jump_format(asm_instr, target26)

    else:
        print("Error: Unknown instruction format.")
        sys.exit(1)

    hex_string_instr = format(int(binary_string_instr, 2), "08X")
    hex_lines.append(hex_string_instr)

with open(file_path_hex, "w") as file:
    for line in hex_lines:
        file.write(line + "\n")
