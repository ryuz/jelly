import sys
import os
import xml.etree.ElementTree as ET
import subprocess
import re

def is_wsl():
    try:
        with open('/proc/version', 'r') as f:
            return 'microsoft' in f.read().lower()
    except Exception:
        return False

def is_windows_path(path):
    # C:\, D:\, \\server\share, //wsl.localhost/ など
    if re.match(r'^[a-zA-Z]:[\\/]', path):
        return True
    if path.startswith('\\') or path.startswith('//'):
        return True
    return False

def convert_path(orig_path, wsl_root, use_wslpath):
    # Windows形式かつWSL2ならwslpathで変換
    if use_wslpath and is_windows_path(orig_path):
        try:
            result = subprocess.run(['wslpath', '-u', orig_path], capture_output=True, text=True)
            wsl_path = result.stdout.strip()
            if os.path.isabs(wsl_path):
                return os.path.relpath(wsl_path, wsl_root)
            else:
                return wsl_path
        except Exception:
            return orig_path
    else:
        # それ以外は絶対パスなら相対パス、相対パスはそのまま
        if os.path.isabs(orig_path):
            return os.path.relpath(orig_path, wsl_root)
        else:
            return orig_path

def main():
    if len(sys.argv) < 2:
        print("Usage: python gowin_path_conv.py <input.gprj> [output.gprj]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file

    wsl_root = os.path.abspath(os.path.dirname(input_file))
    use_wslpath = is_wsl()

    tree = ET.parse(input_file)
    root = tree.getroot()

    for file_elem in root.findall(".//File"):
        path = file_elem.get("path")
        if path:
            new_path = convert_path(path, wsl_root, use_wslpath)
            file_elem.set("path", new_path)

    tree.write(output_file, encoding="utf-8", xml_declaration=True)

if __name__ == "__main__":
    main()
