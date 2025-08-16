import numpy as np

data = np.fromfile("jfive_sample.bin", dtype=np.uint32)

with open("mem.hex", "w") as f:
    i = 0
    for v in data:
        f.write("%08x\n"%(v))
        i += 1
    while i < 0x10000//4:
        f.write("00000000\n")
        i += 1
