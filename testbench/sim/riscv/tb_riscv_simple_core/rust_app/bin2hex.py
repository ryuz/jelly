import numpy as np

data = np.fromfile("test_app.bin", dtype=np.uint32)

with open("mem.hex", "w") as f:
    for v in data:
        f.write("%08x\n"%(v))
