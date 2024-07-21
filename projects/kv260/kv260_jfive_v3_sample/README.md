# Kria KV260 で RISC-V 風のバレルプロセッサ

## 概要

Kria KV260 で RISC-V 風のバレルプロセッサ を動かすサンプルです。


## 環境

### PC環境

vivado2022.2 を用いております。


### KV260環境

[認定Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html) 環境にて試しております。

```
Description : Ubuntu 22.04.4 LTS
kernel      : 5.15.0-1031-xilinx-zynqmp
```


## 動かし方

### gitリポジトリ取得

```
git clone https://github.com/ryuz/jelly.git
```

で一式取得してください。


### PC側の Vivadoで bit ファイルを作る

projects/kv260/kv260_jfive_v3_sample/syn/vivado2022.2

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

