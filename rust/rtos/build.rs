use cc::Build;
//use std::{env, error::Error, fs::File, io::Write, path::PathBuf};
use std::{env, error::Error}; // , path::PathBuf};

fn main() -> Result<(), Box<dyn Error>> {
    let target = env::var("TARGET").unwrap();

    /*
    {
        use std::fs::File;
        use std::io::Write;
        let mut file = File::create("env_list_.txt")?;
        for (key, value) in env::vars() {
            write!(file, "{}: {}\n", key, value)?;
        }
        file.flush()?;
    }
    */

    if target.contains("armv7r") {
        // ソースファイル
        let src_files = vec![
            ["src/arm.S", "arm"],
        ];

        for name in src_files.into_iter() {
            Build::new()
                .flag("-mfpu=vfpv3-d16")
                .flag("-mthumb-interwork")
                .flag("-mfloat-abi=softfp")
                .flag("-D_KERNEL_ARM_WITH_VFP")
                .flag("-Wno-unused-parameter")
                .flag("-Wno-missing-field-initializers")
                .file(name[0])
                .compile(name[1]);
        }
    }

    Ok(())
}
