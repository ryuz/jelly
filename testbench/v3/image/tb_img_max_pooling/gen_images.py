#!/usr/bin/env python3

import argparse
from pathlib import Path


def reflect101(index: int, size: int) -> int:
    if size <= 1:
        return 0
    value = index
    while value < 0 or value >= size:
        if value < 0:
            value = -value
        if value >= size:
            value = 2 * size - 2 - value
    return value


def generate_input(width: int, height: int):
    image = []
    for y in range(height):
        row = []
        for x in range(width):
            row.append([
                (x * 17 + y * 3) & 0xFF,
                (x * 5 + y * 29 + 11) & 0xFF,
                (x * 13 + y * 7 + 19) & 0xFF,
            ])
        image.append(row)
    return image


def pooling_samples(image, n: int, m: int, operation: str):
    height = len(image)
    width = len(image[0]) if height > 0 else 0

    samples = []
    for y in range(height):
        for x in range(width):
            if (y % n) != (n - 1):
                continue
            if (x % m) != (m - 1):
                continue

            out_pix = [0, 0, 0]
            for ch in range(3):
                acc = 0
                for dy in range(n):
                    for dx in range(m):
                        sy = reflect101(y - dy, height)
                        sx = reflect101(x - dx, width)
                        val = image[sy][sx][ch]
                        if operation == "max":
                            if val > acc:
                                acc = val
                        else:
                            acc |= val
                out_pix[ch] = acc
            samples.append(out_pix)

    return samples


def pooled_size(length: int, kernel: int) -> int:
    if length < kernel:
        return length
    return length // kernel


def write_ppm(path: Path, width: int, height: int, pixels):
    with path.open("w", encoding="ascii") as fp:
        fp.write("P3\n")
        fp.write(f"{width} {height}\n")
        fp.write("255\n")
        for pix in pixels:
            for channel in pix:
                fp.write(f"{channel:3d}\n")


def main():
    parser = argparse.ArgumentParser(description="Generate input/expected images for jelly3_img_max_pooling TB")
    parser.add_argument("--width", type=int, default=16)
    parser.add_argument("--height", type=int, default=12)
    parser.add_argument("--n", type=int, default=3)
    parser.add_argument("--m", type=int, default=3)
    parser.add_argument("--operation", choices=["or", "max"], default="max")
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--expected", type=Path, required=True)
    args = parser.parse_args()

    src_img = generate_input(args.width, args.height)

    src_pixels = []
    for y in range(args.height):
        for x in range(args.width):
            src_pixels.append(src_img[y][x])

    args.input.parent.mkdir(parents=True, exist_ok=True)
    args.expected.parent.mkdir(parents=True, exist_ok=True)

    write_ppm(args.input, args.width, args.height, src_pixels)

    exp_pixels = pooling_samples(src_img, args.n, args.m, args.operation)
    exp_width = pooled_size(args.width, args.m)
    exp_height = pooled_size(args.height, args.n)
    write_ppm(args.expected, exp_width, exp_height, exp_pixels)


if __name__ == "__main__":
    main()
