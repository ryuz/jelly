
# ZynqMP で RPU を利用するサンプル

## 事前準備

ZynqMP 環境の Linux で /sys/class/remoteproc/ の下に RPU(Cortex-R5) が見える状態になっていることが前提です。

Ultra96V2(Debian) と Kria K260(Ubuntu) の2つの環境で確認しており、どちらも UART2 に出力しています。

### Ultra96V2 + Debian 環境の場合

[Debian](https://qiita.com/ikwzm/items/c7687406e82ab95ac697) 環境にて APU上で Linux が動いている想定です。

また DeviceTree を編集して [APUからRPUを認識](https://qiita.com/Ryuz/items/c972485f4bd4ec97153d)できるようになっている想定です。

なお、ビルドもAPUで行ってしまう想定ですが、コンパイル自体はPCなどの別環境でも可能です。

### Kria KV260 + Ubuntu 環境の場合

[認定Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html) 環境にて APU上で Linux が動いている想定です。

また DeviceTree を編集して [APUからRPUを認識](https://ryuz.hatenablog.com/entry/2022/05/04/100016)できるようになっている想定です。


### クロスコンパイラインストール

C++/Rust ともに下記のインストールが必要です。

```
sudo apt install gcc-arm-none-eabi
sudo apt install libnewlib-arm-none-eabi
```

### Rust インストール

Rust版 を試す場合は

https://www.rust-lang.org/ja/tools/install

に従ってインストールしてください。

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

下記のように Cortex-R5 用の準備を行います。

```
rustup update
rustup install beta
rustup default beta

rustup target add armv7r-none-eabi
cargo install cargo-binutils
rustup component add llvm-tools-preview
```

## ビルドと実行

C++版は zynqmp_rpu_cpp Rust版は zynqmp_rpu_rust のディレクトリでそれぞれ以下を実行ください。

デフォルトで UART2 に出力するようにしているので、UART1 を使う場合はソースを書き換えてください。


### ビルド

下記のコマンドでビルドできます。

```
make
```


## 実行

実行するには

```
make run
```

で起動し、

```
make stop
```

で停止します。

結果は UART に出力されます。
