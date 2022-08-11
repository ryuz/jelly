#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import os
import glob

TOP_DIR = "../.."
RTL_DIR = os.path.join(TOP_DIR, "rtl") 

TOP_MACRO = "$(JELLY_TOP_DIR)"


sv_files   = glob.glob(os.path.join(RTL_DIR, "**/*.sv"))
vlog_files = glob.glob(os.path.join(RTL_DIR, "**/*.v"))

def write_files(f, macro_name, files):
    files.sort()

    first = True
    for file in files:
        if "model" not in file and "_." not in file:
            file = file.replace(TOP_DIR, TOP_MACRO)

            s = " " if first else "+"
            first= False
            f.write("{} {}= {}\n".format(macro_name, s, file))

with open("def_sources.inc", "w") as f:
    f.write("# Jelly source files\n")
    f.write("\n\n")
    write_files(f, "JELLY_VLOG_SOURCES", vlog_files)
    f.write("\n\n")
    write_files(f, "JELLY_SV_SOURCES", sv_files)
    f.write("\n\n")
    f.write("JELLY_RTL_SOURCES = $(JELLY_VLOG_SOURCES) $(JELLY_SV_SOURCES)\n")
    f.write("\n\n")
