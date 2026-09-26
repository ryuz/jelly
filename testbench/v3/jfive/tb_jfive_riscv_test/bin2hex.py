#!/usr/bin/env python3

import argparse
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(
        description="Convert a binary file to 32-bit Verilog $readmemh format."
    )
    parser.add_argument("size", type=lambda value: int(value, 0), help="Output size in 32-bit words")
    parser.add_argument("input_file", type=Path, help="Input binary file")
    args = parser.parse_args()

    if args.size < 0:
        parser.error("size must be non-negative")

    data = args.input_file.read_bytes()[:args.size * 4]
    data = data.ljust(args.size * 4, b"\0")

    for offset in range(0, len(data), 4):
        word = int.from_bytes(data[offset:offset + 4], byteorder="little")
        print(f"{word:08x}")


if __name__ == "__main__":
    main()
