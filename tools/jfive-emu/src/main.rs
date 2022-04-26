

use std::rc::Rc;
use std::cell::RefCell;

mod memory;
use memory::*;

mod emulation;
use emulation::*;


fn main() {
    let mut map = MemoryMap::new();

    let mem = Memory::new(16 * 1024);
    map.add(0x8000_0000, Rc::new(RefCell::new(mem)));

    let prt = MemStdout::new(0x100);
    map.add(0xf000_0100, Rc::new(RefCell::new(prt)));


    map.load_hex32("./mem.hex", 0x8000_0000);

    run_jfive(&mut map, 0x80000000, 200);
}
