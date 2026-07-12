#!/usr/bin/env python3

import argparse
import numpy as np

parser = argparse.ArgumentParser(description='Convert binary file to hex format.')
parser.add_argument('input_file', help='Input binary file')
parser.add_argument('output_file', help='Output hex file')
parser.add_argument('size', type=lambda x: int(x, 0), help='Size to pad the data to (decimal or hex)')

args = parser.parse_args()

data = np.fromfile(args.input_file, dtype=np.uint32)
data = np.pad(data, (0, args.size - len(data)), 'constant')

with open(args.output_file, "w") as f:
    for v in data:
        f.write(f"{v:08x}\n")
