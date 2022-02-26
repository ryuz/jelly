import numpy as np

data = np.fromfile("rust_app.bin", dtype=np.uint32)

with open("../mem.hex", "w") as f:
    for v in data:
        f.write("%08x\n"%(v))
