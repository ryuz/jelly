use std::fs::File;
use std::io::Write;

use crate::*;


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

fn ridx_to_name(idx: u32) -> String {
    // RISC-Vの対応するレジスタ名を返す
    format!("x{}", idx)
    /*
    match idx {
        0 => "zero",
        1 => "ra",
        2 => "sp",
        3 => "gp",
        4 => "tp",
        5 => "t0",
        6 => "t1",
        7 => "t2",
        8 => "s0",
        9 => "s1",
        10 => "a0",
        11 => "a1",
        12 => "a2",
        13 => "a3",
        14 => "a4",
        15 => "a5",
        16 => "a6",
        17 => "a7",
        18 => "s2",
        19 => "s3",
        20 => "s4",
        21 => "s5",
        22 => "s6",
        23 => "s7",
        24 => "s8",
        25 => "s9",
        26 => "s10",
        27 => "s11",
        28 => "t3",
        29 => "t4",
        30 => "t5",
        31 => "t6",
    }
    */
}

pub fn run_jfive<T: memory::MemAccess>(mem:&mut T, init_pc: u32, cycle: usize, logfile: &mut File, logmem: bool) {
    let mut pc: u32 = init_pc;
    let mut regs: [i32; 32] = [0; 32];

    for _ in 0..cycle {
        // instruction fetch
        let instr = mem.read32(pc as usize);

        // decode
        let (opcode, _) = bit_select(instr, 6, 0);
        let (mut rd_idx, _) = bit_select(instr, 11, 7);
        let (mut rs1_idx, _) = bit_select(instr, 19, 15);
        let (mut rs2_idx, _) = bit_select(instr, 24, 20);
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

        let mut rs1_en = false;
        let mut rs2_en = false;
        if opcode == 0b1100111 { rs1_en = true; }
        if opcode == 0b1100011 { rs1_en = true; rs2_en = true; }
        if opcode == 0b0000011 { rs1_en = true; }
        if opcode == 0b0100011 { rs1_en = true; rs2_en = true; }
        if opcode == 0b0010011 { rs1_en = true; }
        if opcode == 0b0010011 { rs1_en = true; }
        if opcode == 0b0110011 { rs1_en = true; rs2_en = true; }
        if opcode == 0b0001111 { rs1_en = true; }
        if !rs1_en { rs1_idx = 0; }
        if !rs2_en { rs2_idx = 0; }
        let rs1_val = regs[rs1_idx as usize];
        let rs2_val = regs[rs2_idx as usize];

        let mnemonic: String;
        let mut rd_val: i32 = 0;
        let mut branch_pc: u32 = pc + 4;
        let mut mem_access: String = String::new();


        match (opcode, funct3, funct7) {
            (0b0110111, _, _) => {
                mnemonic = format!("lui   {}, 0x{:x}", ridx_to_name(rd_idx), imm_u);
                rd_val = imm_u;
            }
            (0b0010111, _, _) => {
                mnemonic = format!("auipc {}, 0x{:x}", ridx_to_name(rd_idx), imm_u);
                rd_val = imm_u + (pc as i32);
            }
            (0b1101111, _, _) => {
                mnemonic = format!("jal   {}, 0x{:x}", ridx_to_name(rd_idx), imm_j);
                rd_val = pc as i32 + 4;
                branch_pc = (pc as i32 + imm_j) as u32;
            }
            (0b1100111, 0b000, _) => {
                mnemonic = format!("jalr  {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = pc as i32 + 4;
                branch_pc = (rs1_val + imm_i) as u32;
            }
            (0b1100011, 0b000, _) => {
                mnemonic = format!("beq   {}, {}, 0x{:x}", ridx_to_name(rs1_idx), ridx_to_name(rs2_idx), imm_b);
                if rs1_val == rs2_val {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b1100011, 0b001, _) => {
                mnemonic = format!("bne   {}, {}, 0x{:x}", ridx_to_name(rs1_idx), ridx_to_name(rs2_idx), imm_b);
                if rs1_val != rs2_val {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b1100011, 0b100, _) => {
                mnemonic = format!("blt   {}, {}, 0x{:x}", ridx_to_name(rs1_idx), ridx_to_name(rs2_idx), imm_b);
                if rs1_val < rs2_val {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b1100011, 0b101, _) => {
                mnemonic = format!("bge   {}, {}, 0x{:x}", ridx_to_name(rs1_idx), ridx_to_name(rs2_idx), imm_b);
                if rs1_val >= rs2_val {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b1100011, 0b110, _) => {
                mnemonic = format!("bltu  {}, {}, 0x{:x}", ridx_to_name(rs1_idx), ridx_to_name(rs2_idx), imm_b);
                if (rs1_val as u32) < (rs2_val as u32) {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b1100011, 0b111, _) => {
                mnemonic = format!("bgeu  {}, {}, 0x{:x}", ridx_to_name(rs1_idx), ridx_to_name(rs2_idx), imm_b);
                if (rs1_val as u32) >= (rs2_val as u32) {
                    branch_pc = (pc as i32 + imm_b) as u32;
                }
                rd_idx = 0;
            }
            (0b0000011, 0b000, _) => {
                mnemonic = format!("lb    {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = mem.read8i((rs1_val + imm_i) as u32 as usize) as i32;
                mem_access = format!("read b  {:x} => {:08x}", (rs1_val + imm_i) as u32 as usize, rd_val);
            }
            (0b0000011, 0b001, _) => {
                mnemonic = format!("lh    {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = mem.read16i((rs1_val + imm_i) as u32 as usize) as i32;
                mem_access = format!("read h  {:x} => {:08x}", (rs1_val + imm_i) as u32 as usize, rd_val);
            }
            (0b0000011, 0b010, _) => {
                mnemonic = format!("lw    {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = mem.read32i((rs1_val + imm_i) as u32 as usize) as i32;
                mem_access = format!("read w  {:x} => {:08x}", (rs1_val + imm_i) as u32 as usize, rd_val);
            }
            (0b0000011, 0b100, _) => {
                mnemonic = format!("lbu   {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = mem.read8((rs1_val + imm_i) as u32 as usize) as i32;
                mem_access = format!("read bu {:x} => {:08x}", (rs1_val + imm_i) as u32 as usize, rd_val);
            }
            (0b0000011, 0b101, _) => {
                mnemonic = format!("lhu   {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = mem.read16((rs1_val + imm_i) as u32 as usize) as i32;
                mem_access = format!("read hu {:x} => {:08x}", (rs1_val + imm_i) as u32 as usize, rd_val);
            }
            (0b0100011, 0b000, _) => {
                mnemonic = format!("sb    {}, {}, 0x{:x}", ridx_to_name(rs2_idx), ridx_to_name(rs1_idx), imm_i);
                mem.write8((rs1_val + imm_s) as u32 as usize, rs2_val as u8);
                mem_access = format!("write b {:x} <= {:02x}", (rs1_val + imm_s) as u32 as usize, rs2_val as u8);
                rd_idx = 0;
            }
            (0b0100011, 0b001, _) => {
                mnemonic = format!("sh    {}, {}, 0x{:x}", ridx_to_name(rs2_idx), ridx_to_name(rs1_idx), imm_i);
                mem.write16((rs1_val + imm_s) as u32 as usize, rs2_val as u16);
                mem_access = format!("write h {:x} <= {:04x}", (rs1_val + imm_s) as u32 as usize, rs2_val as u16);
                rd_idx = 0;
            }
            (0b0100011, 0b010, _) => {
                mnemonic = format!("sw    {}, {}, 0x{:x}", ridx_to_name(rs2_idx), ridx_to_name(rs1_idx), imm_i);
                mem.write32((rs1_val + imm_s) as u32 as usize, rs2_val as u32);
                mem_access = format!("write w {:x} <= {:08x}", (rs1_val + imm_s) as u32 as usize, rs2_val as u32);
                rd_idx = 0;
            }
            (0b0010011, 0b000, _) => {
                mnemonic = format!("addi  {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = rs1_val.wrapping_add(imm_i);
            }
            (0b0010011, 0b010, _) => {
                mnemonic = format!("slti  {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = if rs1_val < imm_i { 1 } else { 0 };
            }
            (0b0010011, 0b011, _) => {
                mnemonic = format!("sltiu {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = if (rs1_val as u32) < imm_i_u { 1 } else { 0 };
            }
            (0b0010011, 0b100, _) => {
                mnemonic = format!("xori  {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = rs1_val ^ imm_i;
            }
            (0b0010011, 0b110, _) => {
                mnemonic = format!("ori   {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = rs1_val | imm_i;
            }
            (0b0010011, 0b111, _) => {
                mnemonic = format!("andi  {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), imm_i);
                rd_val = rs1_val & imm_i;
            }
            (0b0010011, 0b001, 0b0000000) => {
                mnemonic = format!("slli  {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), shamt);
                rd_val = rs1_val << shamt;
            }
            (0b0010011, 0b101, 0b0000000) => {
                mnemonic = format!("srli  {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), shamt);
                rd_val = ((rs1_val as u32) >> shamt) as i32;
            }
            (0b0010011, 0b101, 0b0100000) => {
                mnemonic = format!("srai  {}, {}, 0x{:x}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), shamt);
                rd_val = rs1_val >> shamt;
            }
            (0b0110011, 0b000, 0b0000000) => {
                mnemonic = format!("add   {}, {}, {}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), ridx_to_name(rs2_idx));
                rd_val = rs1_val.wrapping_add(rs2_val);
            }
            (0b0110011, 0b000, 0b0100000) => {
                mnemonic = format!("sub   {}, {}, {}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), ridx_to_name(rs2_idx));
                rd_val = rs1_val.wrapping_sub(rs2_val);
            }
            (0b0110011, 0b001, 0b0000000) => {
                mnemonic = format!("sll   {}, {}, {}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), ridx_to_name(rs2_idx));
                rd_val = rs1_val << (rs2_val & 0x1f);
            }
            (0b0110011, 0b010, 0b0000000) => {
                mnemonic = format!("slt   {}, {}, {}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), ridx_to_name(rs2_idx));
                rd_val = if rs1_val < rs2_val { 1 } else { 0 };
            }
            (0b0110011, 0b011, 0b0000000) => {
                mnemonic = format!("sltu  {}, {}, {}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), ridx_to_name(rs2_idx));
                rd_val = if (rs1_val as u32) < (rs2_val as u32) {
                    1
                } else {
                    0
                };
            }
            (0b0110011, 0b100, 0b0000000) => {
                mnemonic = format!("xor   {}, {}, {}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), ridx_to_name(rs2_idx));
                rd_val = rs1_val ^ rs2_val;
            }
            (0b0110011, 0b101, 0b0000000) => {
                mnemonic = format!("srl   {}, {}, {}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), ridx_to_name(rs2_idx));
                rd_val = ((rs1_val as u32) >> (rs2_val & 0x1f)) as i32;
            }
            (0b0110011, 0b101, 0b0100000) => {
                mnemonic = format!("sra   {}, {}, {}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), ridx_to_name(rs2_idx));
                rd_val = rs1_val >> (rs2_val & 0x1f);
            }
            (0b0110011, 0b110, 0b0000000) => {
                mnemonic = format!("or    {}, {}, {}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), ridx_to_name(rs2_idx));
                rd_val = rs1_val | rs2_val;
            }
            (0b0110011, 0b111, 0b0000000) => {
                mnemonic = format!("and   {}, {}, {}", ridx_to_name(rd_idx), ridx_to_name(rs1_idx), ridx_to_name(rs2_idx));
                rd_val = rs1_val & rs2_val;
            }
            (0b0001111, _, _) => {
                mnemonic = format!("fence");
                rd_idx = 0;
            }
            (_, _, _) => match instr {
                0x00000073 => {
                    mnemonic = format!("ecall");
                    rd_idx = 0;
                }
                0x00100073 => {
                    mnemonic = format!("ebreak");
                    rd_idx = 0;
                }
                _ => {
                    mnemonic = format!("unknown");
                    rd_idx = 0;
                }
            },
        }

        if rd_idx != 0 {
            regs[rd_idx as usize] = rd_val;
        }
        else {
            rd_val = 0;
        }
        
        
        writeln!(logfile,
            "pc:{:08x} instr:{:08x} rd({:2}):{:08x} rs1({:2}):{:08x} rs2({:2}):{:08x} {:8}",
            pc, instr, rd_idx, rd_val, rs1_idx, rs1_val, rs2_idx, rs2_val, mnemonic
        ).unwrap();
        /*
        writeln!(logfile,
            "pc:{:08x} instr:{:08x} rd({:2}):{:08x} rs1({:2}):{:08x} rs2({:2}):{:08x}",
            pc, instr, rd_idx, rd_val, rs1_idx, rs1_val, rs2_idx, rs2_val
        ).unwrap();
        */

        if logmem && mem_access.len() > 0 {
            writeln!(logfile, "{}", mem_access).unwrap();
        }

        pc = branch_pc;
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test() {
        let a = bit_select(0x1234, 7, 0);
        assert_eq!(a, (0x34, 8));
        let b = bit_select(0x7654, 15, 12);
        assert_eq!(b, (0x7, 4));
        println!("0x{:x} {}", a.0, a.1);
        println!("0x{:x} {}", b.0, b.1);
        let c = bit_cat2(b, a);
        assert_eq!(c, (0x734, 12));
        println!("0x{:x} {}", c.0, c.1);
        let c = bit_cat2(a, b);
        println!("0x{:x} {}", c.0, c.1);
        assert_eq!(c, (0x347, 12));
    }
}
