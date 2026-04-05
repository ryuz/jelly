#!/usr/bin/env python
# -*- coding: utf-8 -*-

# makefile 用の include ファイルを作る

import sys
import os
import glob
import re

TOP_DIR = "../.."
RTL_DIR = os.path.join(TOP_DIR, "rtl") 

TOP_MACRO = "$(JELLY_TOP_DIR)"


def remove_ignore_file(file_list):
    """無視ファイルの除去"""
    new_list = []
    for file in file_list:
        if "model" not in file and "dependencies" not in file and "_." not in file and " " not in file:
            new_list.append(file)
    return new_list


def get_module_name(file_name):
    """モジュール名の取得"""
    with open(file_name, "r") as f:
        contents = f.read()
    pattern = r"^(module|interface|package)\s+(\w+)\s*"
    match = re.search(pattern, contents, re.MULTILINE)
    if match:
        return match.group(2)
    else:
        print(f"Error: module name not found {file_name}")
#       assert(0)
        return None


def write_files(f, macro_name, files):
    """ファイル書き込み"""
    files.sort()

    first = True
    for file in files:
        if "model" not in file and "_." not in file:
            file = file.replace(TOP_DIR, TOP_MACRO)

            s = " " if first else "+"
            first= False
            f.write("{} {}= {}\n".format(macro_name, s, file))



# ファイル一覧取得
vlog_files  = glob.glob(os.path.join(RTL_DIR, "v1/**/*.v"), recursive=True)
vlog_files  = remove_ignore_file(vlog_files)

sv_files    = glob.glob(os.path.join(RTL_DIR, "v2/**/*.sv"), recursive=True)
sv_files   += glob.glob(os.path.join(RTL_DIR, "v3/**/*.sv"), recursive=True)
sv_files    = remove_ignore_file(sv_files)

veryl_files = glob.glob(os.path.join(RTL_DIR, "jellyvl/**/*.sv"), recursive=True)
veryl_files = remove_ignore_file(veryl_files)


# モジュール名重複チェック
modules = dict()
for fn in sv_files + vlog_files:
    module_name = get_module_name(fn)
    if module_name is not None:
        if module_name in modules:
            print(f"Duplicate module name definitions : {module_name}")
            print(f"  {modules[module_name]}")
            print(f"  {fn}")
            assert(0)
        modules[module_name] = fn

# ファイル出力
with open("def_sources.inc", "w") as f:
    f.write("# Jelly source files\n")
    f.write("\n\n")
    write_files(f, "JELLY_VLOG_SOURCES", vlog_files)
    f.write("\n\n")
    write_files(f, "JELLY_SV_SOURCES", sv_files)
    f.write("\n\n")
    write_files(f, "JELLYVL_SV_SOURCES", veryl_files)
    f.write("\n\n")
    f.write("JELLY_RTL_SOURCES = $(JELLY_VLOG_SOURCES) $(JELLY_SV_SOURCES)\n")
    f.write("\n\n")
