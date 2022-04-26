//use std::fs::File;
//use std::io::{BufRead, BufReader};
use std::rc::Rc;
use std::cell::RefCell;

mod memory;
use memory::*;

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


fn run_jfive<T: memory::MemAccess>(mem:&mut T, init_pc: u32, cycle: usize) {
    let mut pc: u32 = init_pc;
    let mut regs: [i32; 32] = [0; 32];

    for _ in 0..cycle {
        // instruction fetch
        let instr = mem.read32(pc as usize);

        // decode
        let (opcode, _) = bit_select(instr, 6, 0);
        let (mut rd_idx, _) = bit_select(instr, 11, 7);
        let (rs1_idx, _) = bit_select(instr, 19, 15);
        let (rs2_idx, _) = bit_select(instr, 24, 20);
        let (funct3, _) = bit_select(instr, 14, 12);
        let (funct7, _) = bit_select(instr, 31, 25);
        let (shamt, _) = bit_select(instr, 24, 20);

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
        let mut mem_access: String = String::new();

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
                if rs1_val == rs2_val {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b1100011, 0b001, _) => {
                mnemonic = "bne";
                if rs1_val != rs2_val {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b1100011, 0b100, _) => {
                mnemonic = "blt";
                if rs1_val < rs2_val {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b1100011, 0b101, _) => {
                mnemonic = "bge";
                if rs1_val >= rs2_val {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b1100011, 0b110, _) => {
                mnemonic = "bltu";
                if (rs1_val as u32) < (rs2_val as u32) {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b1100011, 0b111, _) => {
                mnemonic = "bgeu";
                if (rs1_val as u32) >= (rs2_val as u32) {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b0000011, 0b000, _) => {
                mnemonic = "lb";
                rd_val = mem.read8i((rs1_val + imm_i) as u32 as usize) as i32;
                mem_access = format!("read b  {:x} => {:08x}", (rs1_val + imm_i) as u32 as usize, rd_val);
            }
            (0b0000011, 0b001, _) => {
                mnemonic = "lh";
                rd_val = mem.read16i((rs1_val + imm_i) as u32 as usize) as i32;
                mem_access = format!("read h  {:x} => {:08x}", (rs1_val + imm_i) as u32 as usize, rd_val);
            }
            (0b0000011, 0b010, _) => {
                mnemonic = "lw";
                rd_val = mem.read32i((rs1_val + imm_i) as u32 as usize) as i32;
                mem_access = format!("read w  {:x} => {:08x}", (rs1_val + imm_i) as u32 as usize, rd_val);
            }
            (0b0000011, 0b100, _) => {
                mnemonic = "lbu";
                rd_val = mem.read8((rs1_val + imm_i) as u32 as usize) as i32;
                mem_access = format!("read bu {:x} => {:08x}", (rs1_val + imm_i) as u32 as usize, rd_val);
            }
            (0b0000011, 0b101, _) => {
                mnemonic = "lhu";
                rd_val = mem.read16((rs1_val + imm_i) as u32 as usize) as i32;
                mem_access = format!("read hu {:x} => {:08x}", (rs1_val + imm_i) as u32 as usize, rd_val);
            }
            (0b0100011, 0b000, _) => {
                mnemonic = "sb";
                let addr = 
                mem.write8((rs1_val + imm_s) as u32 as usize, rs2_val as u8);
                mem_access = format!("write b {:x} <= {:02x}", (rs1_val + imm_s) as u32 as usize, rs2_val as u8);
                rd_idx = 0;
            }
            (0b0100011, 0b001, _) => {
                mnemonic = "sh";
                mem.write16((rs1_val + imm_s) as u32 as usize, rs2_val as u16);
                mem_access = format!("write h {:x} <= {:04x}", (rs1_val + imm_s) as u32 as usize, rs2_val as u16);
                rd_idx = 0;
            }
            (0b0100011, 0b010, _) => {
                mnemonic = "sw";
                mem.write32((rs1_val + imm_s) as u32 as usize, rs2_val as u32);
                mem_access = format!("write w {:x} <= {:08x}", (rs1_val + imm_s) as u32 as usize, rs2_val as u32);
                rd_idx = 0;
            }
            (0b0010011, 0b000, _) => {
                mnemonic = "addi";
                rd_val = rs1_val + imm_i;
            }
            (0b0010011, 0b010, _) => {
                mnemonic = "slti";
                rd_val = if rs1_val < imm_i { 1 } else { 0 };
            }
            (0b0010011, 0b011, _) => {
                mnemonic = "sltiu";
                rd_val = if (rs1_val as u32) < imm_i_u { 1 } else { 0 };
            }
            (0b0010011, 0b100, _) => {
                mnemonic = "xori";
                rd_val = rs1_val ^ imm_i;
            }
            (0b0010011, 0b110, _) => {
                mnemonic = "ori";
                rd_val = rs1_val | imm_i;
            }
            (0b0010011, 0b111, _) => {
                mnemonic = "andi";
                rd_val = rs1_val & imm_i;
            }
            (0b0010011, 0b001, 0b0000000) => {
                mnemonic = "slli";
                rd_val = rs1_val << shamt;
            }
            (0b0010011, 0b101, 0b0000000) => {
                mnemonic = "srli";
                rd_val = ((rs1_val as u32) >> shamt) as i32;
            }
            (0b0010011, 0b101, 0b0100000) => {
                mnemonic = "srai";
                rd_val = rs1_val >> shamt;
            }
            (0b0110011, 0b000, 0b0000000) => {
                mnemonic = "add";
                rd_val = rs1_val + rs2_val;
            }
            (0b0110011, 0b000, 0b0100000) => {
                mnemonic = "sub";
                rd_val = rs1_val - rs2_val;
            }
            (0b0110011, 0b001, 0b0000000) => {
                mnemonic = "sll";
                rd_val = rs1_val << (rs2_val & 0x1f);
            }
            (0b0110011, 0b010, 0b0000000) => {
                mnemonic = "slt";
                rd_val = if rs1_val < rs2_val { 1 } else { 0 };
            }
            (0b0110011, 0b011, 0b0000000) => {
                mnemonic = "sltu";
                rd_val = if (rs1_val as u32) < (rs2_val as u32) {
                    1
                } else {
                    0
                };
            }
            (0b0110011, 0b100, 0b0000000) => {
                mnemonic = "xor";
                rd_val = rs1_val ^ rs2_val;
            }
            (0b0110011, 0b101, 0b0000000) => {
                mnemonic = "srl";
                rd_val = ((rs1_val as u32) >> (rs2_val & 0x1f)) as i32;
            }
            (0b0110011, 0b101, 0b0100000) => {
                mnemonic = "sra";
                rd_val = rs1_val >> (rs2_val & 0x1f);
            }
            (0b0110011, 0b110, 0b0000000) => {
                mnemonic = "or";
                rd_val = rs1_val | rs2_val;
            }
            (0b0110011, 0b111, 0b0000000) => {
                mnemonic = "and";
                rd_val = rs1_val & rs2_val;
            }
            (0b0001111, _, _) => {
                mnemonic = "fence";
                rd_idx = 0;
            }
            (_, _, _) => match instr {
                0x00000073 => {
                    mnemonic = "ecall";
                    rd_idx = 0;
                }
                0x00100073 => {
                    mnemonic = "ebreak";
                    rd_idx = 0;
                }
                _ => {
                    mnemonic = "unknown";
                    rd_idx = 0;
                }
            },
        }

        if rd_idx != 0 {
            regs[rd_idx as usize] = rd_val;
        }

        //        println!("{}", mnemonic);
        println!(
            "{:8} pc:{:08x} instr:{:08x} rd({:2}):{:08x} rs1({:2}):{:08x} rs2({:2}):{:08x}",
            mnemonic, pc, instr, rd_idx, rd_val, rs1_idx, rs1_val, rs2_idx, rs2_val
        );
        if mem_access.len() > 0 {
            println!("{}", mem_access);
        }

        pc = branch_pc;
    }
}

fn main() {
//  println!("Hello, world!");

    let mut map = memory::MemoryMap::new();

    let mut mem = memory::Memory::new(16 * 1024);
    map.add(0x8000_0000, Rc::new(RefCell::new(mem)));

    map.load_hex32("./mem.hex", 0x8000_0000);

    //    for i in 0..3 {
    //        println!("{:x}", mem.read32(mem_offset + i));
    //    }

    run_jfive(&mut map, 0x80000000, 200);
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
