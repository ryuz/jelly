# Kria KV260 で RISC-V ハードウェアマルチスレッドを動かすサンプル

## 概要

Kria KV260 で RISC-V でハードウェアマルチスレッドを動かすサンプルを動かすサンプルです。

レジスタファイルを Block-RAM で構成すると、汎用レジスタを複数セットもてるだけの容量がある為、プログラムカウンタも複数持たせることでハードウェアマルチスレッドを実現しています。

当初、[バレルプロセッサ](https://ja.wikipedia.org/wiki/%E3%83%90%E3%83%AC%E3%83%AB%E3%83%97%E3%83%AD%E3%82%BB%E3%83%83%E3%82%B5)を意識しておりましたが、有効になっているPCのみを実行する方式であるため、[細粒度マルチスレッディング](https://ja.wikipedia.org/wiki/%E3%83%8F%E3%83%BC%E3%83%89%E3%82%A6%E3%82%A7%E3%82%A2%E3%83%9E%E3%83%AB%E3%83%81%E3%82%B9%E3%83%AC%E3%83%83%E3%83%87%E3%82%A3%E3%83%B3%E3%82%B0)に分類されるようです。

複数スレッドを交互に実行する為、N個のスレッドを作るとスレッド単独の性能は 1/N になりますが、パイプラインハザードの発生頻度が下がり、分岐ミスのペナルティーも減少する為全体のスループットは若干が向上します。

なお、例によって、最小の命令セットである RV32I 命令セットのみの簡易版 RISC-V コアとなっており、割り込みすら実装していません。

一方で、将来的な方向性としては、[ハードウェア RTOS](https://github.com/ryuz/jelly/tree/master/projects/kv260/kv260_rtos_sample) のようなものと組み合わせて、割り込みを使わないスレッドの起動／停止や、スレッド間同期などをハードウェアで実現するようなものを目指しています。


## 環境

### PC環境

vivado2024.2 を用いております。

### KV260環境

PMOD端子の [3:0] に LEDを接続し、[7:4] に UART を接続して使う想定にしています。

[認定Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html) 環境にて試しております。

```
Description : Ubuntu 24.04.3 LTS
kernel      : 6.8.0-1021-xilinx
```

#### 必要なツールのインストール

```bash
sudo apt update
sudo apt install gcc-riscv64-unknown-elf

rustup update
rustup target add riscv32i-unknown-none-elf
```


## 動かし方

### gitリポジトリ取得

```
git clone https://github.com/ryuz/jelly.git
```

で一式取得してください。


### PC側の Vivadoで bit ファイルを作る

projects/kv260/kv260_jfive_v3_sample/syn/vivado2024.2

に移動して Vivado から kv260_jfive_v3_sample.xpr を開いてください。

最初に BlockDesign を tcl から再構成する必要がります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている i_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。


design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば

kv260_jfive_v3_sample.runs/impl_1

に kv260_jfive_v3_sample.bit が出来上がります。


### KV260 でPSソフトをコンパイルして実行

projects/kv260/kv260_jfive_v3_sample/app の内容一式と先ほど合成した kv260_jfive_v3_sample.bit を、KV260 の Ubuntu で作業できる適当なディレクトリにコピーします。bitファイルも同じ app ディレクトリに入れてください。

を、KV260 側では Ubuntu が起動済みで ssh などで接続ができている前提ですので scp や samba などでコピーすると良いでしょう。app に関しては を、KV260 から git で clone することも可能です。

この時、

- bootgen や RISC-V のクロスコンパイラや Rust など必要なツールがインストールできていること
- sudo 権限のあるユーザーで実行すること

などの下準備がありますので、ブログなど参考に設定ください。

問題なければ、app をコピーしたディレクトリでb

```
make all
```

と実行すれば kv260_jfive_v3_sample.out という実行ファイルが生成されます。

ここで

```
make run
```

とすると、Device Tree overlay によって、bit ファイルの書き込みなどを行った後にプログラムが起動します。

なお、Device Tree overlay のロード／アンロードは

```
make load
make unload
```

といったコマンドで実施可能です。

