use cc::Build;
use std::{env, error::Error, fs::File, io::Write, path::PathBuf};

fn main() -> Result<(), Box<dyn Error>> {
    // Rust以外のソースコード
    let src_files = vec![
        ["src/crt0.S", "crt0"],
    ];

    for name in src_files.into_iter() {
        Build::new()
            .flag("-march=rv32i")
            .flag("-mabi=ilp32")
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
