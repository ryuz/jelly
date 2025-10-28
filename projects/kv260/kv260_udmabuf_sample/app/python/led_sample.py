import numpy as np
import mmap
import os
import time

def main():
    # uio mmap
    uio_name = '/dev/uio4'
    uio_file = os.open(uio_name, os.O_RDWR | os.O_SYNC)
    uio_mmap = mmap.mmap(uio_file, 0x100000, mmap.MAP_SHARED, mmap.PROT_READ | mmap.PROT_WRITE, offset=0)
    mem_array = np.frombuffer(uio_mmap, np.uint64, 1, 0x8000)

    # LED on/off
    for _ in range(3):
        print('LED ON')
        mem_array[0] = 1
        time.sleep(1)
        print('LED OFF')
        mem_array[0] = 0
        time.sleep(1)

if __name__ == "__main__":
    main()

