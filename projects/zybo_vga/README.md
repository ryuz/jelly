# ZYBO の VGA 出力を使って はじめての FPGA をやってみる(勉強会用)

## 概要
タイトルのとおり、ZYBO で FPGA をやってみるものです。

なんとなく VGA が題材に適していそうだったのと、手元に VGA付きの ZYBO(無印) があったのでこうなりました。

今だと ZYBO-Z7 + PMOD VGA や ZYBO-Z7 に HDMI 出力が正解な気はします。


## 環境

このような環境で実施しております。

- Digilent社 [Zybo Z7](https://reference.digilentinc.com/programmable-logic/zybo/start) 
- [Vivado 2019.2.1](https://japan.xilinx.com/support/download.html)

で、試しております。
最後に Debian Linux から起動するところまで試したい場合は

- [ikwzm氏](https://qiita.com/ikwzm) の [Debianブートイメージ](https://qiita.com/ikwzm/items/7e90f0ca2165dbb9a577)
- bootgen などのXilinxツール

などが必要になります。

基本的な環境構築は[こちらのブログ](https://qiita.com/Ryuz/items/fcda012ce0deeca068c6)でも紹介しておりますので参考にしてください。

ソフトウェアは Debian イメージ上でセルフコンパイル可能ですので、ホストPC側は Vivado のみでも開発が可能です(Vitisなどもある方がよいですが)。


## 動かし方

### gitリポジトリ取得

```
git clone https://github.com/ryuz/jelly.git
```

で一式取得してください。

### プロジェクトの場所

projects/zybo_vga 以下にあります。

### ソースの説明

- zybo_sw.v         スイッチでLEDの点灯を制御する(クロック未使用)
- zybo_led.v        クロックを使ってLEDを点滅させてみる
- zybo_clk.v        Clocking Wizard を使って MMCM を使ってみる
- zybo_vga_simple.v 簡単なVGA種強く
- zybo_vga.v        VGA表示でボールを飛ばしてボタンで速度変更
- zybo_vga_ball.v   簡単なテニス的なもの
- zybo_vga_zynq.v   PS(Linux)からの起動用


### Vivadoで bit ファイルを作る

projects/zybo_vga/syn/vivado2019.2

に移動して Vivado から zybo_vga.xpr を開いてください。

ソースが登録されているので、試したいものを「Set as top」で選んで合成してください。

基本的に JTAG 接続して、Hardware Manager から実行する前提です。

ZYBO のジャンパピンでブートモードをJTAGにしてお試しください。


### Debian Linux から起動する

最後の zybo_vga_zynq.v を合成したものは PS からダウンロードできます。

このデザインを使うときは 最初に BlockDesign を tcl から再構成する必要がります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている i_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。

design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば

zybo_vga.runs/impl_1

に zybo_vga_zynq.bit が出来上がります。


### ZYBO で実行

ZYBO で Debian Linux が実行できる前提です。ZYBO のジャンパピンでブートモードを SD にして、Debian を起動します。

projects/zybo_vga/app の内容一式と先ほど合成した zybo_vga_zynq.bit を、ZYBO の Debian で作業できる適当なディレクトリにコピーします。bitファイルも同じappディレクトリに入れてください。

ZYBO 側では Debian が起動済みで ssh などで接続ができている前提ですので scp や samba などでコピーすると良いでしょう。app に関しては ZYBO から git で clone することも可能です。

この時、

- bootgen など必要なツールがインストールできていること
- sudo 権限のあるユーザーで実行すること

などの下準備がありますので、ブログなど参考に設定ください。

問題なければ、app をコピーしたディレクトリで

```
make load
```

と実行すれば PL に回路がダウンロードされ VGA 表示が行われます。

