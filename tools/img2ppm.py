#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import numpy as np
import cv2
import argparse


def img2ppm(src, dst, depth=8, *, src_depth=None, width=None, height=None):
    # ありのまま読む
    img = cv2.imread(src, cv2.IMREAD_UNCHANGED)

    # ch は 1 か 3 のみ
    img = img.reshape(img.shape[0], img.shape[1], -1)
    h = img.shape[0]
    w = img.shape[1]
    c = img.shape[2]
    assert(c == 1 or c == 3)

    # src_depth 指定が無ければファイルのdepthを採用
    if src_depth is None:
        if img.dtype == np.uint8:  src_depth = 8
        if img.dtype == np.uint16: src_depth = 16
        assert(src_depth is not None)
    
    # depth調整
    img = img.astype(np.uint16) * (0xffff // (2**src_depth-1))    # 一旦16bit に拡張
    img = (img >> (16 - depth))

    # resize
    if width is not None or height is not None:
        if width is not None:   w = width
        if height is not None:  h = height
        img = cv2.resize(img, (w, h))

    # to color
    if c == 1:
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)

    with open(dst, "w") as f:
        f.write("P3\n")
        f.write("{} {}\n".format(w, h))
        f.write("{}\n".format(2**depth-1))
        for v in img[:,:,::-1].flatten():
            f.write("{}\n".format(v))


def main():
    parser = argparse.ArgumentParser(description="image to pgm file converter")
    parser.add_argument("input_file",  help="input file")    # 必須の引数を追加
    parser.add_argument("output_file", help="output file")
    parser.add_argument("-d", "--depth", type=int, default=8)
    parser.add_argument("-sd", "--src_depth", type=int)
    parser.add_argument("-ow", "--width", type=int)
    parser.add_argument("-oh", "--height", type=int)
    args = parser.parse_args()
    img2ppm(args.input_file, args.output_file,
            depth=args.depth, src_depth=args.src_depth,
            width=args.width, height=args.height)

if __name__ == '__main__':
    main()

