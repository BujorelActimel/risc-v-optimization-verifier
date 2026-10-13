#+feature dynamic-literals
package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

Op :: enum {
	// R-type
	ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU,
	// I-type (arithmetic)
	ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU,
	// I-type (loads)
	LB, LH, LW, LBU, LHU,
	// S-type
	SB, SH, SW,
	// B-type
	BEQ, BNE, BLT, BGE, BLTU, BGEU,
	// U-type
	LUI, AUIPC,
	// J-type
	JAL,
	// I-type (jump)
	JALR,
}

Fmt :: enum { 
	R, S, 
	I, B, 
	I_Load, I_Jump,
	U, J
}

Instr_Entry :: struct {
	op:  Op,
	fmt: Fmt,
}

INSTR_TABLE := map[string]Instr_Entry {
	"add"  = {.ADD,  .R},
	"sub"  = {.SUB,  .R},
	"and"  = {.AND,  .R},
	"or"   = {.OR,   .R},
	"xor"  = {.XOR,  .R},
	"sll"  = {.SLL,  .R},
	"srl"  = {.SRL,  .R},
	"sra"  = {.SRA,  .R},
	"slt"  = {.SLT,  .R},
	"sltu" = {.SLTU, .R},

	"addi"  = {.ADDI,  .I},
	"andi"  = {.ANDI,  .I},
	"ori"   = {.ORI,   .I},
	"xori"  = {.XORI,  .I},
	"slli"  = {.SLLI,  .I},
	"srli"  = {.SRLI,  .I},
	"srai"  = {.SRAI,  .I},
	"slti"  = {.SLTI,  .I},
	"sltiu" = {.SLTIU, .I},

	"lb"  = {.LB,  .I_Load},
	"lh"  = {.LH,  .I_Load},
	"lw"  = {.LW,  .I_Load},
	"lbu" = {.LBU, .I_Load},
	"lhu" = {.LHU, .I_Load},

	"sb" = {.SB, .S},
	"sh" = {.SH, .S},
	"sw" = {.SW, .S},

	"beq"  = {.BEQ,  .B},
	"bne"  = {.BNE,  .B},
	"blt"  = {.BLT,  .B},
	"bge"  = {.BGE,  .B},
	"bltu" = {.BLTU, .B},
	"bgeu" = {.BGEU, .B},

	"lui"   = {.LUI,   .U},
	"auipc" = {.AUIPC, .U},

	"jal"  = {.JAL,  .J},
	"jalr" = {.JALR, .I_Jump},
}

Reg :: distinct u8 // 0..31

Instr :: struct {
	op:  Op,
	rd:  Reg, // unused for S and B types
	rs1: Reg, // unused for U and J types
	rs2: Reg, // unused for I, U, J types
	imm: i32, // unused for R type
}

parse_reg :: proc(s: string) -> (Reg, bool) {
	switch s {
	case "zero":     return 0, true
	case "ra":       return 1, true
	case "sp":       return 2, true
	case "gp":       return 3, true
	case "tp":       return 4, true
	case "t0":       return 5, true
	case "t1":       return 6, true
	case "t2":       return 7, true
	case "s0", "fp": return 8, true
	case "s1":       return 9, true
	case "a0":       return 10, true
	case "a1":       return 11, true
	case "a2":       return 12, true
	case "a3":       return 13, true
	case "a4":       return 14, true
	case "a5":       return 15, true
	case "a6":       return 16, true
	case "a7":       return 17, true
	case "s2":       return 18, true
	case "s3":       return 19, true
	case "s4":       return 20, true
	case "s5":       return 21, true
	case "s6":       return 22, true
	case "s7":       return 23, true
	case "s8":       return 24, true
	case "s9":       return 25, true
	case "s10":      return 26, true
	case "s11":      return 27, true
	case "t3":       return 28, true
	case "t4":       return 29, true
	case "t5":       return 30, true
	case "t6":       return 31, true
	}
    // support for registers x0 .. x31
	if len(s) >= 2 && s[0] == 'x' {
		n, ok := strconv.parse_int(s[1:])
		if ok && n >= 0 && n <= 31 do return Reg(n), true
	}
	return 0, false
}

parse_imm :: proc(s: string) -> (i32, bool) {
	n, ok := strconv.parse_i64(s)
	return i32(n), ok
}

// parses "imm(rs1)" syntax used by loads, stores, and jalr
parse_mem :: proc(s: string) -> (imm: i32, rs1: Reg, ok: bool) {
	paren := strings.index(s, "(")
	if paren < 0 do return
	imm_str := s[:paren]
	reg_str  := strings.trim_right(s[paren+1:], ")")
	imm, ok = parse_imm(imm_str)
	if !ok do return
	rs1, ok = parse_reg(reg_str)
	return
}

parse_file :: proc(file_name: string) -> []Instr {
	data, err := os.read_entire_file_from_path(file_name, context.allocator)
	if err != nil {
		fmt.eprintln(err)
		os.exit(1)
	}

	raw_lines := strings.split_lines(string(data))

	// first pass: collect labels and clean lines
	clean_lines: [dynamic]string
	labels := make(map[string]int)
	instr_idx := 0

	for line in raw_lines {
		l := line
		if idx := strings.index(l, "#"); idx >= 0 {
			l = l[:idx]
		}
		l = strings.trim_space(l)
		if l == "" do continue

		if colon := strings.index(l, ":"); colon >= 0 {
			label := strings.trim_space(l[:colon])
			if !strings.contains(label, " ") && !strings.contains(label, "\"") {
				labels[label] = instr_idx
				l = strings.trim_space(l[colon+1:])
				if l == "" do continue
			}
		}

		if dot := strings.index(l, "."); dot >= 0 do continue

		append(&clean_lines, l)
		instr_idx += 1
	}

	// second pass: parse instructions
	instrs: [dynamic]Instr

	for &line, i in clean_lines {
		line, _ = strings.replace_all(line, ",", " ")
		fields := strings.fields(line)
		if len(fields) == 0 do continue

		entry, found := INSTR_TABLE[fields[0]]
		if !found {
			fmt.eprintfln("unknown instruction: %s", fields[0])
			continue
		}

		instr := Instr{op = entry.op}
		ok := true

		switch entry.fmt {
		case .R: // op rd, rs1, rs2
			instr.rd,  ok = parse_reg(fields[1]); if !ok do break
			instr.rs1, ok = parse_reg(fields[2]); if !ok do break
			instr.rs2, ok = parse_reg(fields[3])

		case .I: // op rd, rs1, imm
			instr.rd,  ok = parse_reg(fields[1]); if !ok do break
			instr.rs1, ok = parse_reg(fields[2]); if !ok do break
			instr.imm, ok = parse_imm(fields[3])

		case .I_Load: // op rd, imm(rs1)
			instr.rd,  ok = parse_reg(fields[1]); if !ok do break
			instr.imm, instr.rs1, ok = parse_mem(fields[2])

		case .S: // op rs2, imm(rs1)
			instr.rs2, ok = parse_reg(fields[1]); if !ok do break
			instr.imm, instr.rs1, ok = parse_mem(fields[2])

		case .B: // op rs1, rs2, label_or_imm
			instr.rs1, ok = parse_reg(fields[1]); if !ok do break
			instr.rs2, ok = parse_reg(fields[2]); if !ok do break
			target := fields[3]
			if imm_val, imm_ok := parse_imm(target); imm_ok {
				instr.imm = imm_val
			} else if idx, lbl_ok := labels[target]; lbl_ok {
				instr.imm = i32(idx - i)
			} else {
				fmt.eprintfln("unknown label: %s", target)
				ok = false
			}

		case .U: // op rd, imm
			instr.rd,  ok = parse_reg(fields[1]); if !ok do break
			instr.imm, ok = parse_imm(fields[2])

		case .J: // jal rd, label_or_imm
			instr.rd, ok = parse_reg(fields[1]); if !ok do break
			target := fields[2]
			if imm_val, imm_ok := parse_imm(target); imm_ok {
				instr.imm = imm_val
			} else if idx, lbl_ok := labels[target]; lbl_ok {
				instr.imm = i32(idx - i)
			} else {
				fmt.eprintfln("unknown label: %s", target)
				ok = false
			}

		case .I_Jump: // jalr rd, imm(rs1)
			instr.rd,  ok = parse_reg(fields[1]); if !ok do break
			instr.imm, instr.rs1, ok = parse_mem(fields[2])
		}

		if !ok {
			fmt.eprintfln("failed to parse: %s", line)
			continue
		}

		append(&instrs, instr)
	}

	fmt.println(labels)

	return instrs[:]
}
