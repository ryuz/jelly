
#![allow(dead_code)]

use std::rc::Rc;
use std::cell::RefCell;
use std::fs::File;
use std::io::{BufRead, BufReader};

pub trait MemAccess {
    fn len(&self) -> usize;
    fn write8(&mut self, addr: usize, data: u8);
    fn read8(&mut self, addr: usize) -> u8;

    fn write16(&mut self, addr: usize, data: u16) {
        self.write8(addr + 0, ((data >> 0) & 0xff) as u8);
        self.write8(addr + 1, ((data >> 8) & 0xff) as u8);
    }

    fn write32(&mut self, addr: usize, data: u32) {
        self.write16(addr + 0, ((data >>  0) & 0xffff) as u16);
        self.write16(addr + 2, ((data >> 16) & 0xffff) as u16);
    }

    fn write64(&mut self, addr: usize, data: u64) {
        self.write32(addr + 0, ((data >>  0) & 0xffffffff) as u32);
        self.write32(addr + 4, ((data >> 32) & 0xffffffff) as u32);
    }

    fn read16(&mut self, addr: usize) -> u16 {
        ((self.read8(addr + 0) as u16) << 0)
        + ((self.read8(addr + 1) as u16) << 8)
    }

    fn read32(&mut self, addr: usize) -> u32 {
        ((self.read16(addr + 0) as u32) << 0)
        + ((self.read16(addr + 2) as u32) << 16)
    }

    fn read64(&mut self, addr: usize) -> u64 {
        ((self.read16(addr + 0) as u64) << 0)
        + ((self.read16(addr + 4) as u64) << 32)
    }

    fn read8i(&mut self, addr: usize) -> i8 {
        self.read8(addr) as i8
    }

    fn read16i(&mut self, addr: usize) -> i16 {
        self.read16(addr) as i16
    }

    fn read32i(&mut self, addr: usize) -> i32 {
        self.read32(addr) as i32
    }

    fn load_hex32(&mut self, fname: &str, offset: usize) {
        let mut addr = offset;
        let f = File::open(fname).unwrap();
        let reader = BufReader::new(f);
        for line in reader.lines() {
            let line = line.unwrap();
            let hex = u32::from_str_radix(&line, 16).unwrap();
            self.write32(addr, hex);
            addr += 4;
        }
    }
}


// Memory map
pub struct MemoryMap {
    map : Vec<(usize, Rc<RefCell<dyn MemAccess>>)>,
}

impl MemoryMap {
    pub fn new() -> Self {
        MemoryMap { map: Vec::<(usize, Rc<RefCell<dyn MemAccess>>)>::new() }
    }

    pub fn add(&mut self, addr: usize, memacc: Rc<RefCell<dyn MemAccess>>) {
        self.map.push((addr, memacc));
    }

    pub fn serach(&self, addr: usize) -> Option<(usize, Rc<RefCell<dyn MemAccess>>)>
    {
        for m in &self.map {
            if addr >= m.0 && addr - m.0 < m.1.borrow().len() {
                return Some((m.0, m.1.clone()));
            }
        }
        None
    }
}

impl MemAccess for MemoryMap {
    fn len(&self) -> usize {0}

    fn write8(&mut self, addr: usize, data: u8) {
        match self.serach(addr) {
            Some(m) => { m.1.borrow_mut().write8(addr-m.0, data); }
            None => { println!("write : {:x} <= {:x}", addr, data)}
        }
    }

    fn read8(&mut self, addr: usize) -> u8 {
        match self.serach(addr) {
            Some(m) => { m.1.borrow_mut().read8(addr-m.0) }
            None => { println!("read : {:x}", addr); 0}
        }
    }
}


// Memory
pub struct Memory {
    mem: Vec<u8>,
}


impl Memory {
    pub fn new(size: usize) -> Self {
        Memory {
            mem: vec![0; size],
        }
    }
}

impl MemAccess for Memory {
    fn len(&self) -> usize {
        self.mem.len()
    }
    fn write8(&mut self, addr: usize, data: u8) {
        self.mem[addr] = data;
    }

    fn read8(&mut self, addr: usize) -> u8 {
        self.mem[addr]
    }
}


// stdout
pub struct MemStdout {
    size: usize,
}


impl MemStdout {
    pub fn new(size: usize) -> Self {
        MemStdout{ size: size}
    }
}

impl MemAccess for MemStdout {
    fn len(&self) -> usize {
        self.size
    }
    fn write8(&mut self, _addr: usize, data: u8) {
        print!("{}", data as char)
    }

    fn read8(&mut self, _addr: usize) -> u8 {
        0
    }
}
