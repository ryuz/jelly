#!/usr/bin/env bash
set -uo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$script_dir"

hex_files=(../hex/*.hex)
if ((${#hex_files[@]} == 0)); then
    echo "No .hex files found in ../hex" >&2
    exit 1
fi

failed_tests=()
for hex_file in "${hex_files[@]}"; do
    test_name=${hex_file##*/}
    printf '\n===== %s =====\n' "$test_name"
    if make clean build run TCM_READMEM_FILE="$hex_file"; then
        printf 'PASS: %s\n' "$test_name"
    else
        printf 'FAIL: %s\n' "$test_name" >&2
        failed_tests+=("$test_name")
    fi
done

if ((${#failed_tests[@]} > 0)); then
    printf '\nFailed tests (%d):\n' "${#failed_tests[@]}" >&2
    printf '  %s\n' "${failed_tests[@]}" >&2
    exit 1
fi

printf '\nAll %d tests passed.\n' "${#hex_files[@]}"