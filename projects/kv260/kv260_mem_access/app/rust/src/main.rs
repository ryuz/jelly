
use core::ptr;
use jelly_mem_access::*;

const TEST_SIZE : usize = 256*1024;

fn main() {
    println!("Hello, world!");

    println!("\nuio open");
//  let uio_fpd0    = UioAccessor::<usize>::new_with_name("uio_pl_fpd0").expect("Failed to open uio");
let uiomem_ocm  = UdmabufAccessor::<usize>::new_with_module_name("uiomem_ocm",  "uiomem", true).expect("Failed to open uiomem_ocm");
let uiomem_fpd0 = UdmabufAccessor::<usize>::new_with_module_name("uiomem_fpd0", "uiomem", true).expect("Failed to open uiomem_fpd0");
//    println!("uio_pl_fpd0 phys addr : 0x{:x}", uio_fpd0.phys_addr());
//    println!("uio_pl_fpd0 size      : 0x{:x}", uio_fpd0.size());
    println!("uiomem_pl_fpd0 phys addr : 0x{:x}", uiomem_fpd0.phys_addr().unwrap());
    println!("uiomem_pl_fpd0 size      : 0x{:x}", uiomem_fpd0.size());

//    let time = read_test(&uio_fpd0, TEST_SIZE);
    let time = read_test(&uiomem_ocm, TEST_SIZE);
    println!("time : {} sec  {:8.2} MByte/s", time, TEST_SIZE as f64 / time / 1024.0 / 1024.0);
    let time = read_test(&uiomem_fpd0, TEST_SIZE);
    println!("time : {} sec  {:8.2} MByte/s", time, TEST_SIZE as f64 / time / 1024.0 / 1024.0);

    let time = write_test(&uiomem_fpd0, TEST_SIZE);
    println!("time : {} sec  {:8.2} MByte/s", time, TEST_SIZE as f64 / time / 1024.0 / 1024.0);

    {
        let start = std::time::Instant::now();
        uiomem_fpd0.sync_for_cpu_all();
    }
    
}




fn dummy_read() {
    // 2MB buffer
    static mut BUF: [u64; 2*1024*1024] = [0; 2*1024*1024];
    // 全領域を volatile read
    unsafe {
        for i in 0..BUF.len() {
            let _ = ptr::read_volatile(&BUF[i]);
        }
    }
}

//fn read_test<T : MemAccess>(mem: &T, size: usize) -> f64 {
fn read_test(mem: &dyn MemAccess, size: usize) -> f64 {
    // キャッシュを飛ばすためにダミーリード
    dummy_read();

    // 時間計測開始
    let start = std::time::Instant::now();

    // ダミーリード
    unsafe {
//      mem.cache_invalidate_all();
        for i in 0..size/8 {
            let _ = mem.read_mem_u64(i*8);
        }
    }

    // 時間計測終了
    let end = std::time::Instant::now();

    unsafe {
        mem.cache_flush_all();
    }

    // 経過時間を秒単位で返す
    let elapsed = end - start;
    elapsed.as_secs_f64()
}


fn write_test(mem: &dyn MemAccess, size: usize) -> f64 {
    // キャッシュを飛ばすためにダミーリード
    dummy_read();
    
    // 時間計測開始
    let start = std::time::Instant::now();

    // ダミーライト
    unsafe {
        for i in 0..size/8 {
            mem.write_mem_u64(i*8, i as u64);
        }
//      mem.cache_flush_all();
    }

    // 時間計測終了
    let end = std::time::Instant::now();

    unsafe {
        mem.cache_invalidate_all();
    }

    // 経過時間を秒単位で返す
    let elapsed = end - start;
    elapsed.as_secs_f64()
}
