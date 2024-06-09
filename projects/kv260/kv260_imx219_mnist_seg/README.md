# Raspberry V2 カメラ の 1000fps で MNIST のセメンティックセグメンテーションを行う

## 概要

Kria KV260 で Raspberry Pi Camera Module V2 (Sony IMX219) を 1000fps で動かして MNIST(手書き文字)のセマンティックセグメンテーションを行うサンプルです。


## 環境

### PC環境

vivado2023.2 を用いております。


### KV260環境

[認定Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html) 環境にて試しております。

```
image       : iot-limerick-kria-classic-desktop-2204-x07-20230302-63.img
Description : Ubuntu 22.04.4 LTS
kernel      : 5.15.0-1027-xilinx-zynqmp
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

projects/kv260/kv260_imx219_mnist_seg/syn/vivado2023.2

に移動して Vivado から kv260_imx219_mnist_seg.xpr を開いてください。

最初に BlockDesign を tcl から再構成する必要がります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている i_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。


design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば

kv260_imx219_mnist_seg.runs/impl_1

に kv260_imx219_mnist_seg.bit が出来上がります。


### KV260 でPSソフトをコンパイルして実行

KV260 側のSDカードにも同様に

```
git clone https://github.com/ryuz/jelly.git
```

で一式取得してください。

SDカードの方の projects/kv260/kv260_imx219_mnist_seg/app に先ほどPCで合成した kv260_imx219_mnist_seg.bit をコピーします。

この時他にも KV260 側は

- OpenCV や bootgen など必要なツールがインストールできていること
- ssh ポートフォワーディングなどで、PCに X-Window が開く状態にしておくこと
- /dev/uio や /dev/i2c-6 などのデバイスのアクセス権が得られること
- sudo 権限のあるユーザーで実行すること

などの下準備がありますので、ブログなど参考に設定ください。

問題なければ、app をコピーしたディレクトリで

```
make all
```

と実行すれば kv260_imx219_mnist_seg.out という実行ファイルが生成されます。

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



## 参考情報

- 作者ブログ記事
    - [LUT-NetworkによるFPGAでの手書き数字(MNIST)のセマンティックセグメンテーション再整理](https://ryuz.hatenablog.com/entry/2021/07/10/101220)
    - [Zybo Z7 への Raspberry Pi Camera V2 接続(MIPI CSI-2受信)](http://ryuz.txt-nifty.com/blog/2018/04/zybo-z7-raspber.html)
    - [Zybo Z7 への Raspberry Pi Camera V2 接続 (1000fps動作)](http://ryuz.txt-nifty.com/blog/2018/05/zybo-z7-raspber.html)

