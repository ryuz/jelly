# Ultra96-V2 で Raspberry Pi Camera Module V2 (Sony IMX219) を DisplayPort から表示

## 概要

Ultra96-V2 で Raspberry Pi Camera Module V2 (Sony IMX219) をDisplayPortから表示するサンプルです。



## 環境

このような環境で実施しております。

- [Ultra96V2](https://www.avnet.com/wps/portal/japan/products/product-highlights/ultra96/)
- [Raspberry Pi Camera Module V2](https://www.raspberrypi.com/products/camera-module-v2/)
- [Vivado 2021.2.1](https://japan.xilinx.com/support/download.html)
- Debianイメージへの OpenCV など各種開発環境のインストール
- X-Window server となるPC (作者は Windows10 + [Xming](https://sourceforge.net/projects/xming/) で実施)
- 自作の[Ultra96V2用マルチI/O拡張カード](https://github.com/ryuz/ultra96v2_multi_io)

基本的な環境構築は[こちらのブログ](https://github.com/ryuz/qrunch_blog/blob/master/entries/public/blog_2019_12_28_10_16_24.md)でも紹介しておりますので参考にしてください。


[Debian GNU/Linux (v2021.1版) ブートイメージ](https://qiita.com/ikwzm/items/a9adc5a7329b2eb36895) 環境にて試しております。

```
image       : https://github.com/ikwzm/ZynqMP-FPGA-Linux/tree/v2021.1.1
Description : Debian GNU/Linux 11
kernel      : 5.10.0-xlnx-v2021.1-zynqmp-fpga
```

PC側の合成環境には Vivado 2021.2 を利用しております。



## 動かし方

### gitリポジトリ取得

```
git clone https://github.com/ryuz/jelly.git
```

で一式取得してください。

### Vivadoで bit ファイルを作る

projects/ultra96v2_imx219_display_port/syn/vivado2021.2

に移動して Vivado から ultra96v2_imx219_display_port.xpr を開いてください。

最初に BlockDesign を tcl から再構成する必要がります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている i_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。


design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば

ultra96v2_imx219_display_port.runs/impl_1

に ultra96v2_imx219_display_port.bit が出来上がります。

### Debian起動時のパラメータ設定(CMA領域増量)

今回の動作では、IMX219イメージセンサーからPL経由で画像を取り込みますが、その際に ikwzm氏の [udmabuf](https://qiita.com/ikwzm/items/cc1bb33ff43a491440ea) を用いて、CMA(DMA Contiguous Memory Allocator)領域から領域を割り当てます。


### Ultra96V2 で実行

projects/ultra96v2_imx219_display_port/app の内容一式と先ほど合成した ultra96v2_imx219_display_port.bit を、Ultra96V2 の Debian で作業できる適当なディレクトリにコピーします。bitファイルも同じappディレクトリに入れてください。

Ultra96V2 側では Debian が起動済みで ssh などで接続ができている前提ですので scp や samba などでコピーすると良いでしょう。app に関しては Ultra96V2 から git で clone することも可能です。

この時、

- OpenCV や bootgen など必要なツールがインストールできていること
- ssh ポートフォワーディングなどで、PCに X-Window が開く状態にしておくこと
- /dev/uio や /dev/i2c-4 などのデバイスのアクセス権が得られること
- sudo 権限のあるユーザーで実行すること

などの下準備がありますので、ブログなど参考に設定ください。

問題なければ、app をコピーしたディレクトリでb

```
make all
```

と実行すれば ultra96v2_imx219_display_port.out という実行ファイルが生成されます。

ここで

```
make run
```

とすると、Device Tree overlay によって、bit ファイルの書き込みなどを行った後にプログラムが起動し、ホストPCの方の X-Window に、カメラ画像が表示されるはずです。

なお、Device Tree overlay のロード／アンロードは

```
make load
make unload
```

といったコマンドで実施可能です。

なお、デフォルトで 1280x720サイズでの撮影モードで起動しますが、

```
make load
./ultra96v2_imx219_display_port.out 1000fps
```

のようにすれば、640x132での 1000fps モードにも切り替わります(カメラが1000fpsで動くだけで、表示は間引かれて60fpsです)。

その他の細かいコマンドは main.cpp の中を確認ください。


## 参考情報

- 作者ブログ記事
    - [Zybo Z7 への Raspberry Pi Camera V2 接続(MIPI CSI-2受信)](http://ryuz.txt-nifty.com/blog/2018/04/zybo-z7-raspber.html)
    - [Zybo Z7 への Raspberry Pi Camera V2 接続 (1000fps動作)](http://ryuz.txt-nifty.com/blog/2018/05/zybo-z7-raspber.html)

- [https://github.com/lvsoft/Sony-IMX219-Raspberry-Pi-V2-CMOS](https://github.com/lvsoft/Sony-IMX219-Raspberry-Pi-V2-CMOS)
    - Raspberry Pi Camera Module V2 の各種情報（IMX219のデータシートあり)
- [https://www.raspberrypi.org/forums/viewtopic.php?t=160611&start=25](https://www.raspberrypi.org/forums/viewtopic.php?t=160611&start=25)
    - 各種情報。[回路図](https://cdn.hackaday.io/images/5813621484631479007.jpg)の情報あり
