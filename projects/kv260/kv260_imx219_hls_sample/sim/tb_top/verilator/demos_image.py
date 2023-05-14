#!/usr/bin/python3
# -*- coding: utf-8 -*-

import numpy as np
import cv2

def write_pgm(fname, img, depth):
    with open(fname, 'w') as f:
        f.write("P2\n")
        f.write("%d %d\n"%(img.shape[1], img.shape[0]))
        f.write("%d\n"%depth)
        for y in range(img.shape[0]):
            for x in range(img.shape[1]):
                f.write("%d\n"%(int(img[y][x]*depth)))

def main():
    img_src = cv2.imread("src_0000.pgm", cv2.IMREAD_ANYDEPTH)
    print(img_src.dtype)
    print(img_src[0])
    img_src *= (2**6)
    cv2.imwrite("bayer.png", img_src)
    img_demos = cv2.cvtColor(img_src, cv2.COLOR_BAYER_BG2BGR)
    cv2.imwrite("demos.png", img_demos)
    
    
if __name__ == '__main__':
    main()