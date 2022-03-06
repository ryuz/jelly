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
-  iwkzm氏の [Debianブートイメージ 2019.2版](https://qiita.com/ikwzm/items/92221c5ea6abbd5e991c)
- Vivado 2019.2

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

