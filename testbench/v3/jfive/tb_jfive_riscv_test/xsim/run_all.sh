#!/usr/bin/env bash
set -uo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$script_dir"

results_file="$script_dir/results_riscv_test.txt"
printf 'RISC-V test results\n===================\n' > "$results_file"

hex_files=(../hex/*.hex)
if ((${#hex_files[@]} == 0)); then
    echo "No .hex files found in ../hex" >&2
    printf 'No .hex files found in ../hex\n' >> "$results_file"
    exit 1
fi

failed_tests=()
passed_count=0
for hex_file in "${hex_files[@]}"; do
    test_name=${hex_file##*/}
    printf '\n===== %s =====\n' "$test_name"
    if make clean build run TCM_READMEM_FILE="$hex_file"; then
        printf 'PASS: %s\n' "$test_name"
        printf 'OK   %s\n' "$test_name" >> "$results_file"
        ((passed_count += 1))
    else
        printf 'FAIL: %s\n' "$test_name" >&2
        printf 'NG   %s\n' "$test_name" >> "$results_file"
        failed_tests+=("$test_name")
    fi
done

printf '\n-------------------\nOK: %d  NG: %d  Total: %d\n' \
    "$passed_count" "${#failed_tests[@]}" "${#hex_files[@]}" >> "$results_file"

if ((${#failed_tests[@]} > 0)); then
    printf '\nFailed tests (%d):\n' "${#failed_tests[@]}" >&2
    printf '  %s\n' "${failed_tests[@]}" >&2
    exit 1
fi

printf '\nAll %d tests passed.\n' "${#hex_files[@]}"