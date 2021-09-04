
# Rust版 サンプル


## 事前準備

Ultra96V2などの ZynqMP 環境でAPU(Cortex-R5)上で、[Debian](https://qiita.com/ikwzm/items/c7687406e82ab95ac697)などが動く状態になっており、Rust インストール済みの想定です。

また、[APUからRPUを認識](https://qiita.com/Ryuz/items/c972485f4bd4ec97153d)できるようになっている想定です。


なお、ビルドもAPUで行ってしまう想定ですが、コンパイル自体はPCなどの別環境でも可能です。


### Rust インストール

https://www.rust-lang.org/ja/tools/install
に従ってインストール

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### クロスコンパイラ準備

```
sudo apt install gcc-arm-none-eabi
sudo apt install libnewlib-arm-none-eabi
```

### Cortex-R5 用準備

```
rustup update
rustup install nightly
rustup default nightly

rustup target add armv7r-none-eabi
cargo install cargo-binutils
rustup component add llvm-tools-preview
```


## ビルド

```
cargo build
```


## 実行

APUから

```
./run.sh
```

で起動し、

```
./stop.sh
```

で停止します。
