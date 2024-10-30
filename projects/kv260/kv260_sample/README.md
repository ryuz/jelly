# Kria KV260 で LED チカチカ を試すサンプル


## 概要

[KV260](https://www.amd.com/ja/products/system-on-modules/kria/k26/kv260-vision-starter-kit.html)で LED チカチカを試すサンプルです。

[KV260のLチカ](https://zenn.dev/ryuz88/articles/kv260_led_blinking) 記事も合わせてご参照ください。


## 事前準備

### 環境

環境は Vivado 2022.2 or 2023.2 と [公認Ubuntu](https://ubuntu.com/download/amd) を利用しています。
作者の環境ではバージョンは下記の通りでした。

```
Description:    Ubuntu 22.04.4 LTS
kernel:         5.15.0-1031-xilinx-zynqmp
```


### KV260側の準備

bootgen を使うのでインストールしておきます。

```
git clone https://github.com/Xilinx/bootgen  
cd bootgen/  
make  
sudo cp bootgen /usr/local/bin/
```

他にも make や dtc など使うので、不足があれば随時 sudu apt install してください。


### ソースコードの取得

```
git clone https://github.com/ryuz/jelly
```

で取得できます。

/projects/kv260/kv260_sample/

以下が今回のプロジェクトです。


## PL用 bitstream の作成

PS用のbitstreamは PC(WindowsやLinuxなど)で Vivado を使って行います。

Vivado のプロジェクトは

/projects/kv260/kv260_sample/syn/vivado2022.2/kv260_sample.xpr

にありますので Vivado で開いてください。


最初に BlockDesign を tcl から再構成する必要がります。
これはLEDチカチカとは本質的には関係ないのですが、PS が PL を経由して、冷却ファンを制御しているため経路を設定しておく必要があるようです。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている u_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。

design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば
kv260_sample.bit が出来上がります。

このファイルを projects/kv260/kv260_sample/app にコピーしておいてください。



## PS からの実行

  KV260側での PS から PL に回路をダウンロードします。
  projects/kv260/kv260_sample/app を KV260 のどこか適当な箇所にコピーします。

  KV260 の Linux側で git clone する手もあります。

  （余談ですが、作者はVS code Remote Development を使ってセルフコンパイル開発してそのままpushしています。）

### 動かしてみる

sudoできるユーザーで app ディレクトリに移動してください。

```
make run
```

とすればひとまず動くように作っております。
途中、sudo コマンドを使っているのでパスワードを聞かれると思いますが入力ください。
DeviceTree overlay の為にルート権限が必要なためです。


## シミュレーション

projects/kv260/kv260_sample/sim 以下にシミュレーション環境を作っています。

- projects/kv260/kv260_sample/sim/xsim          : xsim用
- projects/kv260/kv260_sample/sim/verilator     : verilator用
- projects/kv260/kv260_sample/sim/verilator_cpp : verilator でテストドライバをC++で書いたもの

いずれもそれぞれのディレクトリで make と実行することで、シミュレーションが動きます。

.vcd もしくは .fst ファイルとして波形が生成されるので、gtkwave などの波形ビューワーで確認ください。



# 実行時の詳細解説

make run などの実行時に Makefile の中で行っている処理を解説します。

## Device Tree overlay

  今回は Device Tree overlay によって

- bitfile のダウンロード

のみを行います。

kv260_sample.dts が Device Tree overlay のソースファイルとなります。

順にみていきたいと思います。
なお、dtsファイルのコンパイルは、実行環境で行うことが必要なようです(内部で既存のDevice Treeのシンボルを参照する為)。

### bitstream 指定

``` 
    fragment@0 {
        target = <&fpga_full>;
        overlay0: __overlay__ {
            #address-cells = <2>;
            #size-cells = <2>;
            firmware-name = "kv260_sample.bit.bin";
        };
    };
```

上のように指定します。この時、 kv260_sample.bit.bin は bitstream から bootgen で生成されたファイルであり、/lib/firmware に置かれている必要があります。

bootgen の使い方としては、下記のような kv260_sample.bif に対して

```kv260_sample.bif
all:
{
    kv260_sample.bit
}
```

bootgenを用いて

```
bootgen -image kv260_sample.bif -arch zynqmp -process_bitstream bin
```

と実行することによって得られます。
上書きを許可する場合にはさらに -w を付けます。


### dtcでのコンパイル

```
dtc -I dts -O dtb -o kv260_sample.dtbo kv260_sample.dts
```

とすることで kv260_sample.dtbo を得ることができます。

## Overlay

いよいよ overlay です

### configfs の mount

初めに configfs をマウントします。

```
sudo mkdir -p /configfs
sudo mount -t configfs configfs /configfs
```

詳しくは[こちら](https://qiita.com/ikwzm/items/ec514e955c16076327ce)や[こちら](https://dora.bk.tsukuba.ac.jp/~takeuchi/?%E9%9B%BB%E6%B0%97%E5%9B%9E%E8%B7%AF%2Fzynq%2FDevice%20Tree%20Overlay)を参考にさせて頂いております。


### ファームウェアのコピー

必要なものを  /lib/firmware にコピーします。

```
sudo mkdir -p /lib/firmware
sudo cp kv260_sample.bit.bin /lib/firmware
sudo cp kv260_sample.dtbo /lib/firmware
```

### overlay 

次に overlay を行います。

```
sudo sh -c "echo 0 > /sys/class/fpga_manager/fpga0/flags"
sudo mkdir /configfs/device-tree/overlays/full
sudo sh -c "echo -n kv260_sample.dtbo > /configfs/device-tree/overlays/full/path"
```

この段階で bitstream は書き込まれ、動作を開始しています。

### 状態確認

状態を確認するには

```
cat /configfs/device-tree/overlays/full/status
```

でできるようで applied と表示されればよいようです。

役目を終えたファイルは削除してよいようです。

```
sudo rm /lib/firmware/kv260_sample.dtbo
sudo rm /lib/firmware/kv260_sample.bit.bin
```



## Device Tree Overlay の解除

```
sudo rmdir /configfs/device-tree/overlays/full
```

と削除すると、解除できるようです。

