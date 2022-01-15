# Memory Mapped I/O access library

[![Crates.io][crates-badge]][crates-url]
[![MIT licensed][license-badge]][license-url]

[crates-badge]: https://img.shields.io/crates/v/jelly-mem_access.svg
[crates-url]: https://crates.io/crates/jelly-mem_access
[license-badge]: https://img.shields.io/github/license/ryuz/jelly
[license-url]: https://github.com/ryuz/jelly/blob/master/license.txt


## Overview

This is a library for accessing memory-mapped I/O.

It assists register access using UIO(User space I/O) and bare-metal access with no_std.

It also assists access using [u-dma-buf](https://github.com/ikwzm/udmabuf/).


## MMIO(Memory Mapped I/O)

mmio access in bare-metal programming can be written as follows.

```rust
    type RegisterWordSize = u64;
    let mmio_acc = MmioAccessor::<RegisterWordSize>::new(0xffff0000, 0x10000);
    mmio_acc.write_mem8 (0x00, 0x12);       // addr : 0xffff0000
    mmio_acc.write_mem16(0x02, 0x1234);     // addr : 0xffff0002
    mmio_acc.write_reg32(0x10, 0x12345678); // addr : 0xffff0080 <= 0x10 * size_of<RegisterWordSize>()
    mmio_acc.read_reg32(0x10);              // addr : 0xffff0080 <= 0x10 * size_of<RegisterWordSize>()
```


## UIO(Userspace I/O)

UIO access in Linux programming can be written as follows.

```rust
    type RegisterWordSize = usize;
    let uio_num = 1;  // ex.) /dev/uio1
    let uio_acc = MmioAccessor::<RegisterWordSize>::new(uio_num);
    uio_acc.set_irq_enable(true);
    uio_acc.write_reg32(0x00, 0x1);
    uio_acc.wait_irq();
```

You can also open it by specifying a name obtained from /sys/class/uio

```rust
    let uio_acc = MmioAccessor::<u32>::new_with_name("uio-sample");
```

## u-dma-buf

[u-dma-buf](https://github.com/ikwzm/udmabuf/) access in Linux programming can be written as follows.

```rust
    let udmabuf_num = 4;  // ex.) /dev/udmabuf4
    let udmabuf_acc = UdmabufAccessor::<usize>::new("udmabuf4" false).unwrap();
    println!("udmabuf4 phys addr : 0x{:x}", udmabuf_acc.phys_addr());
    println!("udmabuf4 size      : 0x{:x}", udmabuf_acc.size());
    udmabuf_acc.write_mem32(0x00, 0x1234);
```
