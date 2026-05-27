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


def pooled_size(length: int, kernel: int) -> int:
    if length < kernel:
        return length
    return length // kernel


def write_ppm(path: Path, width: int, height: int, maxval: int, pixels):
    with path.open("w", encoding="ascii") as fp:
        fp.write("P3\n")
        fp.write(f"{width} {height}\n")
        fp.write(f"{maxval}\n")
        for pix in pixels:
            for channel in pix:
                fp.write(f"{channel:3d}\n")


def pooling_sum_scaled(image, n: int, m: int, mul: int, shift: int, out_bits: int):
    height = len(image)
    width = len(image[0]) if height > 0 else 0
    out_max = (1 << out_bits) - 1

    samples = []
    for y in range(height):
        if (y % n) != (n - 1):
            continue
        for x in range(width):
            if (x % m) != (m - 1):
                continue

            out_pix = [0, 0, 0]
            for ch in range(3):
                total = 0
                for dy in range(n):
                    for dx in range(m):
                        sy = reflect101(y - dy, height)
                        sx = reflect101(x - dx, width)
                        total += image[sy][sx][ch]

                value = (total * mul) >> shift
                if value > out_max:
                    value = out_max
                out_pix[ch] = value

            samples.append(out_pix)

    return samples


def main():
    parser = argparse.ArgumentParser(description="Generate input/expected images for jelly3_img_ave_pooling TB")
    parser.add_argument("--width", type=int, default=16)
    parser.add_argument("--height", type=int, default=12)
    parser.add_argument("--n", type=int, default=3)
    parser.add_argument("--m", type=int, default=3)
    parser.add_argument("--mul", type=int, default=28)
    parser.add_argument("--shift", type=int, default=8)
    parser.add_argument("--out-bits", type=int, default=8)
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

    write_ppm(args.input, args.width, args.height, 255, src_pixels)

    exp_pixels = pooling_sum_scaled(src_img, args.n, args.m, args.mul, args.shift, args.out_bits)
    exp_width = pooled_size(args.width, args.m)
    exp_height = pooled_size(args.height, args.n)
    write_ppm(args.expected, exp_width, exp_height, (1 << args.out_bits) - 1, exp_pixels)


if __name__ == "__main__":
    main()
