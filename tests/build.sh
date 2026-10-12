#!/bin/bash

set -e

usage() {
    echo "Usage: $0 [-O <level>] <file.c>"
    echo "  -O <level>  optimization level: 0, 1, 2, 3, s (default: 0)"
    exit 1
}

OPT=0

while getopts "O:" opt; do
    case $opt in
        O) OPT=$OPTARG ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

[ $# -eq 1 ] || usage

INPUT=$1
OUTPUT="${INPUT%.c}.s"

riscv64-elf-gcc -march=rv32i -mabi=ilp32 -O$OPT -S "$INPUT" -o "$OUTPUT"
echo "compiled $INPUT -> $OUTPUT"
