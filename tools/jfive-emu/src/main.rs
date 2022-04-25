use std::fs::File;
use std::io::{BufRead, BufReader};

struct Memory {
    mem: Vec<u8>,
    offset: usize,
}

#[allow(dead_code)]
impl Memory {
    pub fn new(size: usize, offset: usize) -> Self {
        Memory {
            mem: vec![0; size],
            offset: offset,
        }
    }

    pub fn is_valid(&self, addr: usize) -> bool {
        addr >= self.offset && addr < self.mem.len()
    }

    pub fn write8(&mut self, addr: usize, data: u8) {
        let addr = addr - self.offset;
        self.mem[addr] = data;
    }

    pub fn write16(&mut self, addr: usize, data: u16) {
        let addr = addr - self.offset;
        self.mem[addr + 0] = ((data >> 0) & 0xff) as u8;
        self.mem[addr + 1] = ((data >> 8) & 0xff) as u8;
    }

    pub fn write32(&mut self, addr: usize, data: u32) {
        let addr = addr - self.offset;
        self.mem[addr + 0] = ((data >> 0) & 0xff) as u8;
        self.mem[addr + 1] = ((data >> 8) & 0xff) as u8;
        self.mem[addr + 2] = ((data >> 16) & 0xff) as u8;
        self.mem[addr + 3] = ((data >> 24) & 0xff) as u8;
    }

    pub fn read8(&mut self, addr: usize) -> u8 {
        let addr = addr - self.offset;
        self.mem[addr]
    }

    pub fn read16(&self, addr: usize) -> u16 {
        let addr = addr - self.offset;
        ((self.mem[addr + 0] as u16) << 0) + ((self.mem[addr + 1] as u16) << 8)
    }

    pub fn read32(&self, addr: usize) -> u32 {
        let addr = addr - self.offset;
        ((self.mem[addr + 0] as u32) << 0)
            + ((self.mem[addr + 1] as u32) << 8)
            + ((self.mem[addr + 2] as u32) << 16)
            + ((self.mem[addr + 3] as u32) << 24)
    }

    pub fn read8i(&mut self, addr: usize) -> i8 {
        self.read8(addr) as i8
    }

    pub fn read16i(&mut self, addr: usize) -> i16 {
        self.read16(addr) as i16
    }

    pub fn read32i(&mut self, addr: usize) -> i32 {
        self.read32(addr) as i32
    }

    pub fn load_hex32(&mut self, fname: &str) {
        let mut addr = self.offset;
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

fn bit_select(v: u32, s: u32, e: u32) -> (u32, u32) {
    let len = s - e + 1;
    let msk = (1 << len) - 1;
    ((v >> e) & msk, len)
}

fn bit_cat2((v0, l0): (u32, u32), (v1, l1): (u32, u32)) -> (u32, u32) {
    let v = (v0 << l1) | v1;
    (v, l0 + l1)
}

fn bit_cat(vec: &[(u32, u32)]) -> (u32, u32) {
    let mut v: (u32, u32) = (0, 0);
    for x in vec {
        v = bit_cat2(v, *x);
    }
    v
}

fn bit_sign((v, l): (u32, u32)) -> (i32, u32) {
    let s = 32 - l;
    let ui = v as u32;
    let si = v as i32;
    let ui = ui << s;
    let si = si << s;
    let ui = ui >> s;
    let si = si >> s;
    (si, ui)
}

fn run_jfive(mem: &mut Memory, init_pc: u32, cycle: usize) {
    let mut pc: u32 = init_pc;
    let mut regs: [i32; 32] = [0; 32];

    for _ in 0..cycle {
        // instruction fetch
        let instr = mem.read32(pc as usize);

        // decode
        let (opcode, _) = bit_select(instr, 6, 0);
        let (rd_idx, _) = bit_select(instr, 11, 7);
        let (rs1_idx, _) = bit_select(instr, 19, 15);
        let (rs2_idx, _) = bit_select(instr, 24, 20);
        let (funct3, _) = bit_select(instr, 14, 12);
        let (funct7, _) = bit_select(instr, 31, 25);

        let (imm_i, imm_i_u) = bit_sign(bit_select(instr, 31, 20));
        let (imm_s, _) = bit_sign(bit_cat(&[
            bit_select(instr, 31, 25),
            bit_select(instr, 11, 7),
        ]));
        let (imm_b, _) = bit_sign(bit_cat(&[
            bit_select(instr, 31, 31),
            bit_select(instr, 7, 7),
            bit_select(instr, 30, 25),
            bit_select(instr, 11, 8),
            (0, 1),
        ]));
        let (imm_u, _) = bit_sign(bit_cat(&[bit_select(instr, 31, 12), (0, 12)]));
        let (imm_j, _) = bit_sign(bit_cat(&[
            bit_select(instr, 31, 31),
            bit_select(instr, 19, 12),
            bit_select(instr, 20, 20),
            bit_select(instr, 30, 21),
            (0, 1),
        ]));

        let rs1_val = regs[rs1_idx as usize];
        let rs2_val = regs[rs2_idx as usize];

        let mnemonic: &str;
        let mut rd_val: i32 = 0;
        let mut branch_pc: u32 = pc + 4;

        match (opcode, funct3, funct7) {
            (0b0110111, _, _) => {
                mnemonic = "lui";
                rd_val = imm_u;
            }
            (0b0010111, _, _) => {
                mnemonic = "auipc";
                rd_val = imm_u + (pc as i32);
            }
            (0b1101111, _, _) => {
                mnemonic = "jal";
                rd_val = pc as i32 + 4;
                branch_pc = (pc as i32 + imm_j) as u32;
            }
            (0b1100111, 0b000, _) => {
                mnemonic = "jalr";
                rd_val = pc as i32 + 4;
                branch_pc = (rs1_val + imm_i) as u32;
            }
            (0b1100011, 0b000, _) => {
                mnemonic = "beq";
                if rs1_val == rs2_val { branch_pc = (pc as i32 + imm_b) as u32; }
            }
            (0b1100011, 0b001, _) => {
                mnemonic = "bne";
                if rs1_val != rs2_val { branch_pc = (pc as i32 + imm_b) as u32; }
            }
            (0b1100011, 0b100, _) => {
                mnemonic = "blt";
                if rs1_val < rs2_val { branch_pc = (pc as i32 + imm_b) as u32; }
            }
            (0b1100011, 0b101, _) => {
                mnemonic = "bge";
                if rs1_val >= rs2_val { branch_pc = (pc as i32 + imm_b) as u32; }
            }
            (0b1100011, 0b110, _) => {
                mnemonic = "bltu";
                if (rs1_val as u32) < (rs2_val as u32) { branch_pc = (pc as i32 + imm_b) as u32; }
            }
            (0b1100011, 0b111, _) => {
                mnemonic = "bgeu";
                if (rs1_val as u32) >= (rs2_val as u32) { branch_pc = (pc as i32 + imm_b) as u32; }
            }
            (0b0000011, 0b000, _) => {
                mnemonic = "lb";
                rd_val = mem.read8i((rs1_val + imm_i) as usize) as i32;
            }
            (0b0000011, 0b001, _) => {
                mnemonic = "lh";
                rd_val = mem.read16i((rs1_val + imm_i) as usize) as i32;
            }
            (0b0000011, 0b010, _) => {
                mnemonic = "lw";
                rd_val = mem.read32i((rs1_val + imm_i) as usize) as i32;
            }
            (0b0000011, 0b100, _) => {
                mnemonic = "lbu";
                rd_val = mem.read8((rs1_val + imm_i) as usize) as i32;
            }
            (0b0000011, 0b101, _) => {
                mnemonic = "lhu";
                rd_val = mem.read16((rs1_val + imm_i) as usize) as i32;
            }
            (0b0100011, 0b000, _) => {
                mnemonic = "sb";
                mem.write8((rs1_val + imm_s) as usize, rs2_val as u8);
            }
            (0b0100011, 0b001, _) => {
                mnemonic = "sh";
                mem.write16((rs1_val + imm_s) as usize, rs2_val as u16);
            }
            (0b0100011, 0b010, _) => {
                mnemonic = "sw";
                mem.write32((rs1_val + imm_s) as usize, rs2_val as u32);
            }
            (0b0010011, 0b000, _) => {
                mnemonic = "addi";
            }
            (0b0010011, 0b010, _) => {
                mnemonic = "slti";
            }
            (0b0010011, 0b011, _) => {
                mnemonic = "sltiu";
            }
            (0b0010011, 0b100, _) => {
                mnemonic = "xori";
            }
            (0b0010011, 0b110, _) => {
                mnemonic = "ori";
            }
            (0b0010011, 0b111, _) => {
                mnemonic = "andi";
            }
            (0b0010011, 0b001, 0b0000000) => {
                mnemonic = "slli";
            }
            (0b0010011, 0b101, 0b0000000) => {
                mnemonic = "srli";
            }
            (0b0010011, 0b101, 0b0100000) => {
                mnemonic = "srai";
            }
            (0b0110011, 0b000, 0b0000000) => {
                mnemonic = "add";
            }
            (0b0110011, 0b000, 0b0100000) => {
                mnemonic = "sub";
            }
            (0b0110011, 0b001, 0b0000000) => {
                mnemonic = "sll";
            }
            (0b0110011, 0b010, 0b0000000) => {
                mnemonic = "slt";
            }
            (0b0110011, 0b011, 0b0000000) => {
                mnemonic = "sltu";
            }
            (0b0110011, 0b100, 0b0000000) => {
                mnemonic = "xor";
            }
            (0b0110011, 0b101, 0b0000000) => {
                mnemonic = "srl";
            }
            (0b0110011, 0b101, 0b0100000) => {
                mnemonic = "sra";
            }
            (0b0110011, 0b110, 0b0000000) => {
                mnemonic = "or";
            }
            (0b0110011, 0b111, 0b0000000) => {
                mnemonic = "and";
            }
            (0b0001111, _, _) => {
                mnemonic = "fence";
            }
            (_, _, _) => match instr {
                0x00000073 => {
                    mnemonic = "ecall";
                }
                0x00100073 => {
                    mnemonic = "ebreak";
                }
                _ => {
                    mnemonic = "unknown";
                }
            },
        }

        if rd_idx != 0 {
            regs[rd_idx as usize] = rd_val;
        }

        println!("{}", mnemonic);
        println!(
            "pc:{:08x} instr:{:08x} rd({:2}):{:08x} rs1({:2}):{:08x} rs2({:2}):{:08x}",
            pc, instr, rd_idx, rd_val, rs1_idx, rs1_val, rs2_idx, rs2_val
        );

        pc = branch_pc;
    }
}

fn main() {
    println!("Hello, world!");

    let mem_offset: usize = 0x8000_0000;
    let mut mem = Memory::new(16 * 1024, mem_offset);

    mem.load_hex32("./mem.hex");

    //    for i in 0..3 {
    //        println!("{:x}", mem.read32(mem_offset + i));
    //    }

    run_jfive(&mut mem, 0x80000000, 10);
}

#[test]
fn test() {
    let a = bit_select(0x1234, 7, 0);
    assert_eq!(a, (0x34, 8));
    let b = bit_select(0x7654, 15, 12);
    assert_eq!(b, (0x7, 4));
    println!("0x{:x} {}", a.0, a.1);
    println!("0x{:x} {}", b.0, b.1);
    let c = bit_cat(b, a);
    assert_eq!(c, (0x734, 12));
    println!("0x{:x} {}", c.0, c.1);
    let c = bit_cat(a, b);
    println!("0x{:x} {}", c.0, c.1);
    assert_eq!(c, (0x347, 12));
}
