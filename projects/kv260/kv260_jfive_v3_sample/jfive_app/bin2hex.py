import numpy as np

data = np.fromfile("jfive_app.bin", dtype=np.uint32)
data = np.pad(data, (0, 4096 - len(data)), 'constant')
              
with open("../mem.hex", "w") as f:
    for v in data:
        f.write("%08x\n"%(v))
