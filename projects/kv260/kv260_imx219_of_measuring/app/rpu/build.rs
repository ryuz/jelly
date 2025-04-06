use cc::Build;
use std::{env, error::Error, fs::File, io::Write, path::PathBuf};

fn main() -> Result<(), Box<dyn Error>> {
    // ソースファイル
    let src_files = vec![["src/vectors.S", "vectors"], ["src/startup.S", "startup"]];

    for name in src_files.into_iter() {
        Build::new()
            .flag("-mfpu=vfpv3-d16")
            .flag("-mthumb-interwork")
            .flag("-mfloat-abi=softfp")
            .flag("-Wno-unused-parameter")
            .flag("-Wno-missing-field-initializers")
            //          .flag(&format!("-I{}/include", kernel_path))
            .file(name[0])
            .compile(name[1]);
    }

    // ライブラリパス追加
    let out_dir = PathBuf::from(env::var_os("OUT_DIR").unwrap());
    println!("cargo:rustc-link-search={}", out_dir.display());

    // リンカスクリプトををビルドディレクトリに
    File::create(out_dir.join("link.lds"))?.write_all(include_bytes!("link.lds"))?;

    Ok(())
}
