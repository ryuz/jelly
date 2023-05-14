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
    w = 1024
    h = 768
#   img_src = cv2.imread("Penguins.jpg").astype(np.float32) / 255.0
    img_src = cv2.imread("Chrysanthemum.jpg").astype(np.float32) / 255.0
    img_rgb = cv2.resize(img_src, (w, h))
    img_rgb = cv2.GaussianBlur(img_rgb, (7, 7), 1.0)
    img_bayer = np.ndarray((h, w), np.float32)
    
    img_bayer[0::2,0::2] = img_rgb[0::2,0::2,2]
    img_bayer[0::2,1::2] = img_rgb[0::2,1::2,1]
    img_bayer[1::2,0::2] = img_rgb[1::2,0::2,1]
    img_bayer[1::2,1::2] = img_rgb[1::2,1::2,0]
    
    name = "Chrysanthemum_bayer_%dx%d"%(w, h)
    cv2.imwrite(name + ".png", img_bayer*255)
    write_pgm(name + ".pgm", img_bayer, 1023)

    img_bayer_u8 = (img_bayer*255).astype(np.uint8)
    img_demos = cv2.cvtColor(img_bayer_u8, cv2.COLOR_BAYER_BG2BGR)
    cv2.imwrite("demos.png", img_demos)
    
    
if __name__ == '__main__':
    main()