package main

import "core:os"
import "core:fmt"

main :: proc() {
    if len(os.args) < 2 {
        os.exit(1)
    }

    file_name := os.args[1]
    instrs := parse_file(file_name)
    for &instr in instrs {
        fmt.println(instr)
    }
}
