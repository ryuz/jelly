use cc::Build;
use std::{env, error::Error}; // , path::PathBuf};

fn main() -> Result<(), Box<dyn Error>> {
    let target = env::var("TARGET").unwrap();

    if target.contains("armv7r") {
        // ソースファイル
        let src_files = vec![["src/arm.S", "arm"]];

        for name in src_files.into_iter() {
            Build::new()
                .flag("-mfpu=vfpv3-d16")
                .flag("-mthumb-interwork")
                .flag("-mfloat-abi=softfp")
                .flag("-D_WITH_VFP")
                .flag(if cfg!(feature = "reg64bit") {
                    "-D_RTOS_REG_SIZE=8"
                } else {
                    "-D_RTOS_REG_SIZE=4"
                })
                .flag("-Wno-unused-parameter")
                .flag("-Wno-missing-field-initializers")
                .file(name[0])
                .compile(name[1]);
        }
    }

    Ok(())
}
