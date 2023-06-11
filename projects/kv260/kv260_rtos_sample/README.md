# Kria KV260 で FPGA化した リアルタイムOS を試すサンプル(ブロックデザイン版)


## 概要

PL に RTOS(リアルタイムOS)機能を実装し、RPU(Cortex-R5) を試してみるサンプルです。

基本的には[こちら](../kv260_rtos/README.md)のサンプルと同じですが、以下の二点が異なります。

- AXI4-Light インターフェースを有し、ブロックデザインの中でRTLに接続している
- サンプルプログラムでセマフォを pol_sem() ではなく twai_sem() を使ってタイムアウト付きの待ちを行っている

そのほかは概ね同一です。

## 事前準備

ZynqMP 環境でAPU(Cortex-R5)上で、[Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html)や、[Debian](https://qiita.com/ikwzm/items/a9adc5a7329b2eb36895)などが動く状態になっており、Rust インストール済みの想定です。

また、[APUからRPUを認識](https://ryuz.hatenablog.com/entry/2022/05/04/100016)できるようになっている想定です。

なお、ビルドもAPUで行ってしまう想定ですが、コンパイル自体はPCなどの別環境でも可能です。

## 動作を確認した環境

### PC環境

vivado2022.2 を用いております。

### KV260環境

[認定Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html) 環境にて試しております。

```
image       : iot-limerick-kria-classic-desktop-2204-x06-20220614-78.img
Description : Ubuntu 22.04.2 LTS
kernel      : 5.15.0-1018-xilinx-zynqmp
```

### Rust インストール

https://www.rust-lang.org/ja/tools/install

に従ってインストールください。

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### クロスコンパイラ準備

下記のように Ubuntu にインストールください。

```
sudo apt install gcc-arm-none-eabi
sudo apt install libnewlib-arm-none-eabi
```

### Cortex-R5 用準備

下記のように Ubuntu にインストールください。

```
rustup update

rustup target add armv7r-none-eabi
cargo install cargo-binutils
rustup component add llvm-tools-preview
```

## RPU の ビルド＆実行

app ディレクトリに手
make から cargo などを呼び出す仕組みにしています。

ビルドは

```
make
```

実行は

```
make run
```

停止は

```
make stop
```

となり、[食事する哲学者の問題](https://ja.wikipedia.org/wiki/%E9%A3%9F%E4%BA%8B%E3%81%99%E3%82%8B%E5%93%B2%E5%AD%A6%E8%80%85%E3%81%AE%E5%95%8F%E9%A1%8C)の動作をUART 側に出力するサンプルとして実装しております。

