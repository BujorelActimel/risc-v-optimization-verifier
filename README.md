# RISC-V optimization verifier

This is a program that will take as input 2 risc-v programs (RV32I to be exact) and output whether one of the 
programs is an optimization of the other, or in other words if they are equivalent programs.

[Here](https://courses.cs.cornell.edu/cs3410/2026sp/rsrc/riscv-ref.html) is a nice overview of the RV32I ISA.

[**12-10-2026**] - There seem to be 2 unsupported instructions, `mv` and `jr`
This is the output after running the parser on `./tests/strength_reduction.`
```bash
./risc-v-optimization-verifier ./tests/strength_reduction.s
unknown instruction: mv
unknown instruction: jr
Instr{op = "ADDI", rd = 2, rs1 = 2, rs2 = 0, imm = -32}
Instr{op = "SW", rd = 0, rs1 = 2, rs2 = 1, imm = 28}
Instr{op = "SW", rd = 0, rs1 = 2, rs2 = 8, imm = 24}
Instr{op = "ADDI", rd = 8, rs1 = 2, rs2 = 0, imm = 32}
Instr{op = "SW", rd = 0, rs1 = 8, rs2 = 10, imm = -20}
Instr{op = "LW", rd = 15, rs1 = 8, rs2 = 0, imm = -20}
Instr{op = "SLLI", rd = 15, rs1 = 15, rs2 = 0, imm = 2}
Instr{op = "LW", rd = 1, rs1 = 2, rs2 = 0, imm = 28}
Instr{op = "LW", rd = 8, rs1 = 2, rs2 = 0, imm = 24}
Instr{op = "ADDI", rd = 2, rs1 = 2, rs2 = 0, imm = 32}
```

Also, the original output had additional noise along side the instructions, like in `add.s`. Should format the output to be something like
```asm
func_name:
    instr1
    instr2
    ...
```

[**13-10-2026**] - It turns out that those instructions that are outside the ISA are [pseudo-instructions](https://github.com/riscv-non-isa/riscv-asm-manual/blob/main/src/asm-manual.adoc#pseudoinstructions) emited by the compiler and are translated by the assembler to the real instructions. And the reason is that these pseudo-instructions are easier to understand / are more readable for programmers.  

And sure, I can understand, but from a 30-something instruction set I now have to support quite a few more instructions if I want to be accurate and not fuck around with the output emmited by the compiler every time. 
 
That being said, I have to fuck around with the output regardless, if I want to have the format that I specified yesterday. I could just selectively support some of the pseudo-instructions that appear more often, but I have this stupid sense of supporting everything, otherwise I feel like it's 'fake'.
