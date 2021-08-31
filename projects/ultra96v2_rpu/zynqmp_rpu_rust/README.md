
# Rust版 サンプル

## クロスコンパイラインストール

```
sudo apt install gcc-arm-none-eabi
sudo apt install libnewlib-arm-none-eabi
```

## Rust インストール

https://www.rust-lang.org/ja/tools/install
に従ってインストール

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```


## Cortex-R5 用準備

```
rustup update
rustup install nightly
rustup default nightly

rustup target add armv7r-none-eabi
cargo install cargo-binutils
rustup component add llvm-tools-preview
```


