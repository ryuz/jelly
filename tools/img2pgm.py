#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import numpy as np
import cv2
import argparse


def img2pgm(src, dst, depth=8, src_depth=None):
    if depth == 8 and src_depth is None:
        img = cv2.imread(src, cv2.IMREAD_GRAYSCALE)
    else:
        img = cv2.imread(src, cv2.IMREAD_ANYDEPTH)
        if img.dtype == np.uint8:
            img = img.astype(np.uint16) * 0x0101
            if src_depth is not None:
                src_depth += 8
        if src_depth is None:
            src_depth = 16
        if depth < src_depth:
            img = img >> (src_depth-depth)
        if depth > src_depth:
            img = img << (depth-src_depth)
    
    with open(dst, "w") as f:
        f.write("P2\n")
        f.write("{} {}\n".format(img.shape[1], img.shape[0]))
        f.write("{}\n".format(2**depth-1))
        for v in img.flatten():
            f.write("{}\n".format(v))


def main():
    parser = argparse.ArgumentParser(description="image to pgm file converter")
    parser.add_argument("input_file",  help="input file")    # 必須の引数を追加
    parser.add_argument("output_file", help="output file")
    parser.add_argument("-d", "--depth", default="8")
    parser.add_argument("-sd", "--src_depth")
    args = parser.parse_args()
    dst_depth = args.depth
    src_depth = args.src_depth
    if dst_depth is not None: dst_depth = int(dst_depth)
    if src_depth is not None: src_depth = int(src_depth)
    img2pgm(args.input_file, args.output_file, dst_depth, src_depth)

if __name__ == '__main__':
    main()

