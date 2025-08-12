# Kria KV260 で Raspberry Pi Camera Module V2 (Sony IMX219) を動かす

## 概要

Kria KV260 で Raspberry Pi Camera Module V2 (Sony IMX219) を動かすサンプルです。


## 環境

### PC環境

vivado2021.2 を用いております。


### KV260環境

[認定Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html) 環境にて試しております。

```
image       : iot-kria-classic-desktop-2004-x03-20211110-98.img
Description : Ubuntu 20.04.4 LTS
kernel      : 5.4.0-1017-xilinx-zynqmp
```


### OpenCV

```
sudo apt update
sudo apt install libopencv-dev
```


## 動かし方

### gitリポジトリ取得

```
git clone https://github.com/ryuz/jelly.git
```

で一式取得してください。


### PC側の Vivadoで bit ファイルを作る

projects/kv260/kv260_imx219/syn/vivado2021.2

に移動して Vivado から kv260_imx219.xpr を開いてください。

最初に BlockDesign を tcl から再構成する必要がります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている i_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。


design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば

kv260_imx219.runs/impl_1

に kv260_imx219.bit が出来上がります。


### KV260 でPSソフトをコンパイルして実行

projects/kv260/kv260_imx219/app の内容一式と先ほど合成した kv260_imx219.bit を、KV260 の Ubuntu で作業できる適当なディレクトリにコピーします。bitファイルも同じ app ディレクトリに入れてください。

を、KV260 側では Ubuntu が起動済みで ssh などで接続ができている前提ですので scp や samba などでコピーすると良いでしょう。app に関しては を、KV260 から git で clone することも可能です。

この時、

- OpenCV や bootgen など必要なツールがインストールできていること
- ssh ポートフォワーディングなどで、PCに X-Window が開く状態にしておくこと
- /dev/uio や /dev/i2c-6 などのデバイスのアクセス権が得られること
- sudo 権限のあるユーザーで実行すること

などの下準備がありますので、ブログなど参考に設定ください。

問題なければ、app をコピーしたディレクトリでb

```
make all
```

と実行すれば kv260_imx219.out という実行ファイルが生成されます。

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
./kv260_imx219.out 1000fps
```

のようにすれば、640x132での 1000fps モードにも切り替わります(カメラが1000fpsで動くだけで、表示は間引かれて60fpsです)。

その他の細かいコマンドは main.cpp の中を確認ください。


## 参考情報

- 作者ブログ記事
    - [Zybo Z7 への Raspberry Pi Camera V2 接続(MIPI CSI-2受信)](https://rtc-lab.com/2018/04/29/zybo-rpi-cam-rx/)
    - [Zybo Z7 への Raspberry Pi Camera V2 接続 (1000fps動作)](https://rtc-lab.com/2018/05/06/zybo-rpi-cam-1000fps/)

- [https://github.com/lvsoft/Sony-IMX219-Raspberry-Pi-V2-CMOS](https://github.com/lvsoft/Sony-IMX219-Raspberry-Pi-V2-CMOS)
    - Raspberry Pi Camera Module V2 の各種情報（IMX219のデータシートあり)
- [https://www.raspberrypi.org/forums/viewtopic.php?t=160611&start=25](https://www.raspberrypi.org/forums/viewtopic.php?t=160611&start=25)
    - 各種情報。[回路図](https://cdn.hackaday.io/images/5813621484631479007.jpg)の情報あり
