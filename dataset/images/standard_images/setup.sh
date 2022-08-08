#! /bin/bash

source download.sh

TOOL_DIR=../../../tools


${TOOL_DIR}/img2ppm.py color/Mandrill.bmp color/Mandrill.ppm
${TOOL_DIR}/img2pgm.py color/Mandrill.bmp color/Mandrill.pgm
${TOOL_DIR}/img2ppm.py color/Mandrill.bmp color/Mandrill_256x256.ppm --width 256 --height 256
${TOOL_DIR}/img2pgm.py color/Mandrill.bmp color/Mandrill_256x256.pgm --width 256 --height 256
${TOOL_DIR}/img2ppm.py color/Mandrill.bmp color/Mandrill_128x128.ppm --width 128 --height 128
${TOOL_DIR}/img2pgm.py color/Mandrill.bmp color/Mandrill_128x128.pgm --width 128 --height 128
${TOOL_DIR}/img2pgm.py color/Mandrill.bmp color/Mandrill_256x256_bayer10.pgm  --width 256 --height 256 --bayer --depth 10

${TOOL_DIR}/img2pgm.py mono/BOAT.bmp mono/BOAT_256x256.pgm --width 256 --height 256
${TOOL_DIR}/img2pgm.py mono/BOAT.bmp mono/BOAT_128x128.pgm --width 128 --height 128

