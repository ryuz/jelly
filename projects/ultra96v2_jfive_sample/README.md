# JellyFive (RV32I 互換コア) サンプル

## 概要

Ultra96V2 で 最小セットの RISC-V 互換コアを作ってみたサンプルです。

RISC-V の 最小セット (rv32i) をコンパクトに実装して、BRAM 数個分程度のメモリで動く、小型のコントローラを Rust で開発できるようにしようという試みです。
（かなり適当に作ってるのでちゃんと互換になってるかは結構怪しいですが）。

MicroBlaze 版の Rust があればそれでもよかったのかもしれませんが、半分以上作者の勉強目的という事で。

現在、LEDチカが動いたレベルですが、とりあえず置いておきます。

コンセプトとして APU(Cortex-A53)やRPU(Cortex-R5) でできることをやっても面白みに欠ける点ははあるので、
今回は「コンパクトなプログラマブルシーケンサがRustで書ける」というところをポイントに試作してみました。

PLにCPUを構成するメリットを考えると、他にはPLに構成したDSA(Domain Specific Architecture)なエンジンを
RISC-Vのカスタム命令に割り当てるとかがあるかと思いますが、そのあたりはまたおいおい考えてみたいなと思います。

## 動作環境

環境は下記の通りです。

- [Ultra96V2](https://www.avnet.com/wps/portal/japan/products/product-highlights/ultra96/)
-  iwkzm氏の [Debian GNU/Linux (v2021.1版) ブートイメージ](https://qiita.com/ikwzm/items/a9adc5a7329b2eb36895) 
- Vivado 2021.2

たとえば[こちら](../ultra96v2_udmabuf_sample/README.md)などの他のサンプルと同様に Debian 環境を
前提にしております。

Debianイメージは一度起動SDを作ってしまえば Vivado だけでもいろいろできるのが素敵です。


## RISC-V クロスコンパイル環境

クロスコンパイル環境は、PC や Ultra96V2 上の Linux で構成することができます。

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

/projects/ultra96v2_jfive_sample/syn/vivado2021.2/ultra96v2_jfive_sample.xpr

にありますので Vivado で開いてください。

最初に BlockDesign を tcl から再構成する必要がります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている i_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。

design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば
ultra96v2_jfive_sample.bit が出来上がります。

このファイルを projects/ultra96v2_jfive_sample/app にコピーしておいてください。



## PSソフト側の作成と実行

  Ultra96V2側でのPSソフトのビルドです。
  projects/ultra96v2_jfive_sample/app を Ultra96 のどこか適当な箇所にコピーします。

### 動かしてみる

sudoできるユーザーで app ディレクトリに移動してください。

```
make run
```

Ultra96上で RISC-Vのクロスコンパイル環境やRustの設定ができていれば、これでひとまず動くように作っております。

途中、sudo コマンドを使っているのでパスワードを聞かれると思いますが入力ください。
DeviceTree overlay や uio へのアクセスの為にルート権限が必要なためです。

