#! /bin/bash

source download.sh

TOOL_DIR=../../../tools

${TOOL_DIR}/img2pgm.py Chrysanthemum.jpg Chrysanthemum_640x480.pgm         --width 640 --height 480 --depth 8
${TOOL_DIR}/img2pgm.py Chrysanthemum.jpg Chrysanthemum_320x240.pgm         --width 320 --height 240 --depth 8
${TOOL_DIR}/img2pgm.py Chrysanthemum.jpg Chrysanthemum_640x480_bayer10.pgm --width 640 --height 480 --depth 10 --bayer
${TOOL_DIR}/img2pgm.py Chrysanthemum.jpg Chrysanthemum_320x240_bayer10.pgm --width 320 --height 240 --depth 10 --bayer
${TOOL_DIR}/img2pgm.py Chrysanthemum.jpg Chrysanthemum_640x480_bayer8.pgm  --width 640 --height 480 --depth 8  --bayer
${TOOL_DIR}/img2pgm.py Chrysanthemum.jpg Chrysanthemum_320x240_bayer8.pgm  --width 320 --height 240 --depth 8  --bayer

${TOOL_DIR}/img2pgm.py Penguins.jpg Penguins_640x480.pgm         --width 640 --height 480 --depth 8
${TOOL_DIR}/img2pgm.py Penguins.jpg Penguins_320x240.pgm         --width 320 --height 240 --depth 8
${TOOL_DIR}/img2pgm.py Penguins.jpg Penguins_640x480_bayer10.pgm --width 640 --height 480 --depth 10 --bayer
${TOOL_DIR}/img2pgm.py Penguins.jpg Penguins_320x240_bayer10.pgm --width 320 --height 240 --depth 10 --bayer
${TOOL_DIR}/img2pgm.py Penguins.jpg Penguins_640x480_bayer8.pgm  --width 640 --height 480 --depth 8  --bayer
${TOOL_DIR}/img2pgm.py Penguins.jpg Penguins_320x240_bayer8.pgm  --width 320 --height 240 --depth 8  --bayer

