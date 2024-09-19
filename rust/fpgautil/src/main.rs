use std::error::Error;
use std::process::Command;



fn load_firmware(loadfile: &str) -> Result<(), Box<dyn Error>> {
    // loadfile からパスのファイル名＋拡張子の部分だけ取り出す
//    let fname    = loadfile.split('/').last().unwrap();
//    let firmpath = format!("/sys/class/fpga_manager/{}", fname);

    // /lib/firmware にコピー
    let status = Command::new("sudo")
        .arg("cp")
        .arg(loadfile)
        .arg("/lib/firmware/jelly_tmp.bin")
        .status()?;
    if !status.success() {
        return Err("Failed to copy bitstream file".into());
    }

    // ダウンロード実行
    let status = Command::new("sudo")
        .arg("sh")
        .arg("-c")
        .arg("echo -n jelly_tmp.bin > /sys/class/fpga_manager/fpga0/firmware")
        .status()?;
    if !status.success() {
        return Err("Failed to copy bitstream file".into());
    }

    // ファイル削除
    let status = Command::new("sudo")
        .arg("rm")
        .arg("/lib/firmware/jelly_tmp.bin")
        .status()?;
    if !status.success() {
        return Err("Failed to copy bitstream file".into());
    }

    Ok(())
}



fn main() -> Result<(), Box<dyn Error>> {
    println!("Hello, world!");

    let bin_file = "../kv260_udmabuf_sample.bit";
    load_firmware(bin_file)?;
//    load_firmware("../kv260_imx219.bit.bin")?;

    /*
    let status = Command::new("sudo")
        .arg("cp")
        .arg(bin_file)
        .arg("/lib/firmware/jelly_tmp.bin")
        .status()?;
    //    .expect("Failed to copy bitstream file");
    println!("status: {}", status);
    // status が 0 でなければエラーを返す
    if !status.success() {
        return Err("Failed to copy bitstream file".into());
    }

    let status = Command::new("sudo")
        .arg("sh")
        .arg("-c")
        .arg("echo -n jelly_tmp.bin > /sys/class/fpga_manager/fpga0/firmware")
        .status()?;
    println!("status: {}", status);

    // ファイル削除
    let status = Command::new("sudo")
        .arg("rm")
        .arg("/lib/firmware/jelly_tmp.bin")
        .status()?;
    println!("status: {}", status);

    //    sudo sh -c "echo -n xilinx/k26-starter-kits/k26_starter_kits.bit.bin > /sys/class/fpga_manager/fpga0/firmware"

    //    println!("status: {}", output.status);
    //    println!("stdout: {}", String::from_utf8_lossy(&output.stdout));
    //    println!("stderr: {}", String::from_utf8_lossy(&output.stderr));
    */

    Ok(())
}
