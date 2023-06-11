# Kria KV260 で FPGA化した リアルタイムOS を試すサンプル


## 概要

PL に RTOS(リアルタイムOS)機能を実装し、RPU(Cortex-R5) を試してみるサンプルです。

コンセプトを記載したブログは[こちら](https://ryuz.hatenablog.com/entry/2021/11/23/111925)です。

ITRON風のAPIを、PLのメモリ空間にメモリマップドレジスタとして配置して、タスクスケジューラの機能を実装しています。

PLでの実装により

- タスク数Nに関わらず各種優先度比較に関わる処理が O(1) で完了する
- PLで処理した分 Cortex-R5 の TCM の RTOS での消費を抑えられる
- イベントフラグなどをPLの別の回路から直接セット要求できる

などが特徴となっています。

現時点では割り込み処理はタスクスイッチのみに利用し、いわゆる割り込み処理はPLからイベントフラグなどで直接的に起動したタスクで行う前提としております。

また、PS部からの操作でしかないので APU(Cortex-A53) から set_flg や sig_sem() したりしてプロセッサ間で通信することもおそらく可能と思います。

RPUのTCMに収まるような小規模なリアルタイム制御など、タスク数が少ない範囲ではある程度実用になるのではないかと思い、実験中です。

なお、今回 RPU 側のソフトには Rust を用いております。


## 事前準備

ZynqMP 環境でAPU(Cortex-R5)上で、[Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html)や、[Debian](https://qiita.com/ikwzm/items/a9adc5a7329b2eb36895)などが動く状態になっており、Rust インストール済みの想定です。

また、[APUからRPUを認識](https://ryuz.hatenablog.com/entry/2022/05/04/100016)できるようになっている想定です。

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

