# JellyFive (RV32I 互換コア) サンプル

## 概要

自作の最小セットの RISC-V 互換コアを作ってみたサンプルを Kria KV260 で動かしてみたサンプルです。

RISC-V の 最小セット (rv32i) をコンパクトに実装して、BRAM 数個分程度のメモリで動く、小型のコントローラを Rust で開発できるようにしようという試みです。
（かなり適当に作ってるのでちゃんと互換になってるかは結構怪しいですが）。

コンセプトとして APU(Cortex-A53)やRPU(Cortex-R5) でできることをやっても面白みに欠ける点ははあるので、
今回は「コンパクトなプログラマブルシーケンサがRustで書ける」というところをポイントに試作してみました。

PLにCPUを構成するメリットを考えると、他にはPLに構成したDSA(Domain Specific Architecture)なエンジンを
RISC-Vのカスタム命令に割り当てるとかがあるかと思いますが、そのあたりはまたおいおい考えてみたいなと思います。

## 動作環境

環境は下記の通りです。

- [認定Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html)
- Vivado 2021.2


 Ubuntu は下記のバージョンでした。

```
image       : iot-kria-classic-desktop-2004-x03-20211110-98.img
Description : Ubuntu 20.04.4 LTS
kernel      : 5.4.0-1017-xilinx-zynqmp
```

なお、KV260 には LチカをするためのLEDは実装されておりませんので、PMOD コネクタの端子に信号を出しています。

PMOD端子からLEDを点灯させる回路を用意するか、オシロスコープなどで電圧を観測するかなどで動作確認を実施ください。


## RISC-V クロスコンパイル環境

クロスコンパイル環境は、PC や KV260 上の Linux で構成することができます。

[こちら](https://github.com/riscv-collab/riscv-gnu-toolchain)などを参考に環境構築ください。


以下、私の場合の例ですが、下記のような感じでインストールしました。


```
sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

git clone https://github.com/riscv/riscv-gnu-toolchain
cd riscv-gnu-toolchain
./configure --prefix=$HOME/.opt/riscv
make
```

Rust はインストール済みなのを前提に、RISC-V用の設定として下記など実行しました。

```
rustup update
rustup target add riscv32i-unknown-none-elf
```


## PL用bitstreamの作成

PS用のbitstreamは PC(WindowsやLinuxなど)で Vivado を使って行います。

Vivado のプロジェクトは

/projects/kv260_jfive_simple_controller/syn/vivado2021.2/kv260_jfive_simple_controller.xpr

にありますので Vivado で開いてください。

最初に BlockDesign を tcl から再構成する必要がります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている i_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。

design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば
kv260_jfive_simple_controller.bit が出来上がります。

このファイルを projects/kv260_jfive_simple_controller/app にコピーしておいてください。



## PSソフト側の作成と実行

  KV260 側でのPSソフトのビルドです。
  projects/kv260_jfive_simple_controller/app を KV260 のどこか適当な箇所にコピーします。

### 動かしてみる

sudoできるユーザーで app ディレクトリに移動してください。

```
make run
```

KV260 上で RISC-Vのクロスコンパイル環境やRustの設定ができていれば、これでひとまず動くように作っております。

途中、sudo コマンドを使っているのでパスワードを聞かれると思いますが入力ください。
DeviceTree overlay や uio へのアクセスの為にルート権限が必要なためです。

