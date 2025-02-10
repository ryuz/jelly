# Kria KR260 で LED チカチカ を試すサンプル


## 概要

[KR260](https://www.amd.com/ja/products/system-on-modules/kria/k26/kr260-robotics-starter-kit.html)で LED チカチカを試すサンプルです。

幸い KR260 は PL(Programmable Logic)部に直接つながるクロックも LED もボード上に実装されているため、
[KV260のLチカ](https://zenn.dev/ryuz88/articles/kv260_led_blinking) に比べてだいぶ簡素に試すことが出来ます。


## 事前準備

### 環境

環境は Vivado 2022.2 or 2023.2 と [公認Ubuntu](https://ubuntu.com/download/amd) を利用しています。
作者の環境ではバージョンは下記の通りでした。

```
Description:    Ubuntu 22.04.4 LTS
kernel:         5.15.0-1027-xilinx-zynqmp
```


### KR260側の準備

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

/projects/kr260/kr260_blinking_led/

以下が今回のプロジェクトです。


## PL用 bitstream の作成

PS用のbitstreamは PC(WindowsやLinuxなど)で Vivado を使って行います。

Vivado のプロジェクトは

/projects/kr260/kr260_blinking_led/syn/vivado2022.2/kr260_blinking_led.xpr

にありますので Vivado で開いてください。

この時 design_1.bd や kr260_blinking_led.dcp が無いなどのメッセージが出る事がありますが、
これはこの後作成するファイルがリポジトリには含まれていない為ですので無視して先に進めてください。

最初に BlockDesign を tcl から再構成する必要がります。
これはLEDチカチカとは本質的には関係ないのですが、PS が PL を経由して、冷却ファンを制御しているため経路を設定しておく必要があるようです。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている u_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。

また kr260_blinking_led.dcp についてもエラーが出るようであれば、Sources の Utility Sources の下にある該当ファイルを削除してください。これはビルドすると再度生成されますので削除しても大丈夫です。

design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば
プロジェクトの下の kr260_blinking_led.runs/impl_1 ディレクトリの中に
kr260_blinking_led.bit が出来上がります。

このファイルを projects/kr260/kr260_blinking_led/app にコピーしておいてください。



## PS からの実行

  KR260側での PS から PL に回路をダウンロードします。
  projects/kr260/kr260_blinking_led/app を KR260 のどこか適当な箇所にコピーします。

  KR260 の Linux側で git clone する手もあります。

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

projects/kr260/kr260_blinking_led/sim 以下にシミュレーション環境を作っています。

- projects/kr260/kr260_blinking_led/sim/xsim          : xsim用
- projects/kr260/kr260_blinking_led/sim/verilator     : verilator用
- projects/kr260/kr260_blinking_led/sim/verilator_cpp : verilator でテストドライバをC++で書いたもの

いずれもそれぞれのディレクトリで make と実行することで、シミュレーションが動きます。

.vcd もしくは .fst ファイルとして波形が生成されるので、gtkwave などの波形ビューワーで確認ください。



# 実行時の詳細解説

make run などの実行時に Makefile の中で行っている処理を解説します。

## Device Tree overlay

  今回は Device Tree overlay によって

- bitfile のダウンロード

のみを行います。

kr260_blinking_led.dts が Device Tree overlay のソースファイルとなります。

順にみていきたいと思います。
なお、dtsファイルのコンパイルは、実行環境で行うことが必要なようです(内部で既存のDevice Treeのシンボルを参照する為)。

### bitstream 指定

``` 
    fragment@0 {
        target = <&fpga_full>;
        overlay0: __overlay__ {
            #address-cells = <2>;
            #size-cells = <2>;
            firmware-name = "kr260_blinking_led.bit.bin";
        };
    };
```

上のように指定します。この時、 kr260_blinking_led.bit.bin は bitstream から bootgen で生成されたファイルであり、/lib/firmware に置かれている必要があります。

bootgen の使い方としては、下記のような kr260_blinking_led.bif に対して

```kr260_blinking_led.bif
all:
{
    kr260_blinking_led.bit
}
```

bootgenを用いて

```
bootgen -image kr260_blinking_led.bif -arch zynqmp -process_bitstream bin
```

と実行することによって得られます。
上書きを許可する場合にはさらに -w を付けます。


### dtcでのコンパイル

```
dtc -I dts -O dtb -o kr260_blinking_led.dtbo kr260_blinking_led.dts
```

とすることで kr260_blinking_led.dtbo を得ることができます。

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
sudo cp kr260_blinking_led.bit.bin /lib/firmware
sudo cp kr260_blinking_led.dtbo /lib/firmware
```

### overlay

次に overlay を行います。

```
sudo sh -c "echo 0 > /sys/class/fpga_manager/fpga0/flags"
sudo mkdir /configfs/device-tree/overlays/full
sudo sh -c "echo -n kr260_blinking_led.dtbo > /configfs/device-tree/overlays/full/path"
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
sudo rm /lib/firmware/kr260_blinking_led.dtbo
sudo rm /lib/firmware/kr260_blinking_led.bit.bin
```



## Device Tree Overlay の解除

```
sudo rmdir /configfs/device-tree/overlays/full
```

と削除すると、解除できるようです。

