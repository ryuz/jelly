#!/usr/bin/env python3
"""Apply 3x3 morphology denoising (opening then closing) to a PGM image.

Processing steps:
1) Erode
2) Dilate
3) Dilate
4) Erode
"""

from __future__ import annotations

import argparse
import time
from pathlib import Path

import cv2
import numpy as np


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Read a PGM image and apply 3x3 morphology in 4 stages: "
            "erosion -> dilation -> dilation -> erosion."
        )
    )
    parser.add_argument(
        "-i",
        "--input",
        type=Path,
        default=Path("img_128x128.pgm"),
        help="Input PGM path (default: img_128x128.pgm)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("img_128x128_open_close.pgm"),
        help="Final output image path (default: img_128x128_open_close.pgm)",
    )
    parser.add_argument(
        "--save-stages",
        action="store_true",
        help="Save each stage image as stage1..stage4 PGM files.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    img = cv2.imread(str(args.input), cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise FileNotFoundError(f"Failed to read input image: {args.input}")

    kernel = np.ones((3, 3), dtype=np.uint8)

    t0 = time.perf_counter()

    # 1) opening part
    stage1_erode = cv2.erode(img, kernel, iterations=1)
    stage2_dilate = cv2.dilate(stage1_erode, kernel, iterations=1)

    # 2) closing part
    stage3_dilate = cv2.dilate(stage2_dilate, kernel, iterations=1)
    stage4_erode = cv2.erode(stage3_dilate, kernel, iterations=1)

    elapsed_ms = (time.perf_counter() - t0) * 1000.0

    if not cv2.imwrite(str(args.output), stage4_erode):
        raise OSError(f"Failed to write output image: {args.output}")

    if args.save_stages:
        base = args.output.with_suffix("")
        ext = args.output.suffix if args.output.suffix else ".pgm"
        outputs = {
            f"{base}_stage1_erode{ext}": stage1_erode,
            f"{base}_stage2_dilate{ext}": stage2_dilate,
            f"{base}_stage3_dilate{ext}": stage3_dilate,
            f"{base}_stage4_erode{ext}": stage4_erode,
        }
        for path_str, im in outputs.items():
            if not cv2.imwrite(path_str, im):
                raise OSError(f"Failed to write stage image: {path_str}")

    print("Input :", args.input)
    print("Output:", args.output)
    print("Kernel:", "3x3 ones")
    print("Pipeline: erode -> dilate -> dilate -> erode")
    print(f"Morphology time: {elapsed_ms:.3f} ms")


if __name__ == "__main__":
    main()
