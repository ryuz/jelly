# Kria KV260 で PL -> RPU の割り込みを試すサンプル


## 概要

[KV260](https://www.amd.com/ja/products/system-on-modules/kria/k26/kv260-vision-starter-kit.html)で RPU を試すサンプルです。

LED チカチカをベースに PL の割り込みを RPU に入れるサンプルです。

LED点滅信号をそのまま IRQ入力に接続して、エッジ割り込みとして受けています。

RPUのコードを Rust で書いておりますが [main.rs](./app/rust/src/main.rs) でベアメタルでの割り込み設定や、割り込みハンドラなどが参考になれば幸いです。


なお PL の割り込みを APU(Linux) に入れる場合は UIO の利用が便利であり、[こちら](https://github.com/ryuz/jelly/tree/master/projects/kv260/kv260_udmabuf_sample)などにサンプルがあります。


下記の記事なども合わせてご参照ください。

- [ARMの割り込みPL390(GIC)設定やHOS-V4aのZynq対応メモ](https://ryuz.hatenablog.com/entry/2021/04/03/194046)
- [KV260でSystemVerilogでLEDチカしてみる](https://zenn.dev/ryuz88/articles/kv260_led_blinking)
- [Kria KV260 環境構築メモ：RPU (Cortex-R5) を認識させる](https://zenn.dev/ryuz88/articles/kv260_setup_memo_ubuntu22#rpu-(cortex-r5)-%E3%82%92%E8%AA%8D%E8%AD%98%E3%81%95%E3%81%9B%E3%82%8B)
- [Pudding-RTOS：カーネル無し Rust版 サンプル](https://github.com/ryuz/pudding-rtos/tree/master/samples/zynqmp_rpu_no_kernel)


## 事前準備

### 環境

環境は Vivado と [公認Ubuntu](https://ubuntu.com/download/amd) を利用しています。
作者の環境ではバージョンは下記の通りでした。

```
Description:    Ubuntu 22.04.4 LTS
kernel:         5.15.0-1031-xilinx-zynqmp
```


### KV260側の準備

bootgen を使うのでインストールしておきます。

```bash
git clone https://github.com/Xilinx/bootgen
cd bootgen/
make
sudo cp bootgen /usr/local/bin/
```

他にも make や dtc など使うので、不足があれば随時 sudu apt install してください。


### ソースコードの取得

```bash
git clone https://github.com/ryuz/jelly
```

で取得できます。

/projects/kv260/kv260_rpu_sample/

以下が今回のプロジェクトです。


## PL用 bitstream の作成

PS用のbitstreamは PC(WindowsやLinuxなど)で Vivado を使って行います。

Vivado のプロジェクトは

/projects/kv260/kv260_rpu_sample/syn/vivado2022.2/kv260_rpu_sample.xpr

にありますので Vivado で開いてください。


最初に BlockDesign を tcl から再構成する必要がります。
これはLEDチカチカとは本質的には関係ないのですが、PS が PL を経由して、冷却ファンを制御しているため経路を設定しておく必要があるようです。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている u_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。

design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば
kv260_rpu_sample.bit が出来上がります。

このファイルを projects/kv260/kv260_rpu_sample/app にコピーしておいてください。



## PS からの実行

  KV260側での PS から PL に回路をダウンロードします。
  projects/kv260/kv260_rpu_sample/app を KV260 のどこか適当な箇所にコピーします。

  KV260 の Linux側で git clone する手もあります。

  （余談ですが、作者はVS code Remote Development を使ってセルフコンパイル開発してそのままpushしています。）

### Rust インストール

KV260側の Linux で Rust のコンパイルが出来るようにします。

https://www.rust-lang.org/ja/tools/install
に従ってインストール

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### RPU用クロスコンパイラ準備

```
sudo apt install gcc-arm-none-eabi
sudo apt install libnewlib-arm-none-eabi
```

### Cortex-R5 用準備

```
rustup update

rustup target add armv7r-none-eabi
cargo install cargo-binutils
rustup component add llvm-tools
```


### 動かしてみる

sudoできるユーザーで app ディレクトリに移動してください。

```bash
make run
```

とすればひとまず動くように作っております。
途中、sudo コマンドを使っているのでパスワードを聞かれると思いますが入力ください。
DeviceTree overlay の為にルート権限が必要なためです。


## シミュレーション

projects/kv260/kv260_blinking_led/sim 以下にシミュレーション環境を作っています。

- projects/kv260/kv260_blinking_led/sim/xsim          : xsim用
- projects/kv260/kv260_blinking_led/sim/verilator     : verilator用
- projects/kv260/kv260_blinking_led/sim/verilator_cpp : verilator でテストドライバをC++で書いたもの

いずれもそれぞれのディレクトリで make と実行することで、シミュレーションが動きます。

.vcd もしくは .fst ファイルとして波形が生成されるので、gtkwave などの波形ビューワーで確認ください。



# 実行時の詳細解説

make run などの実行時に Makefile の中で行っている処理を解説します。

## 元からある回路の解除

Ubuntu 起動時に dfx-mgr で管理されている初期回路がある場合は

```bash
sudo xmutil unloadapp
```

としてアンロードしておきます。

## Device Tree overlay

  今回は Device Tree overlay によって

- bitfile のダウンロード

のみを行います。

kv260_blinking_led.dts が Device Tree overlay のソースファイルとなります。

順にみていきたいと思います。
なお、dtsファイルのコンパイルは、実行環境で行うことが必要なようです(内部で既存のDevice Treeのシンボルを参照する為)。

### bitstream 指定

```dts
    fragment@0 {
        target = <&fpga_full>;
        overlay0: __overlay__ {
            #address-cells = <2>;
            #size-cells = <2>;
            firmware-name = "kv260_rpu_sample.bit.bin";
        };
    };
```

上のように指定します。この時、 kv260_rpu_sample.bit.bin は bitstream から bootgen で生成されたファイルであり、/lib/firmware に置かれている必要があります。

bootgen の使い方としては、下記のような kv260_rpu_sample.bif に対して

```kv260_blinking_led.bif
all:
{
    kv260_rpu_sample.bit
}
```

bootgenを用いて

```bash
bootgen -image kv260_rpu_sample.bif -arch zynqmp -process_bitstream bin
```

と実行することによって得られます。
上書きを許可する場合にはさらに -w を付けます。


### dtcでのコンパイル

```bash
dtc -I dts -O dtb -o kv260_rpu_sample.dtbo kv260_rpu_sample.dts
```

とすることで kv260_blinking_led.dtbo を得ることができます。

## Overlay

いよいよ overlay です

### configfs の mount

初めに configfs をマウントします。

```bash
sudo mkdir -p /configfs
sudo mount -t configfs configfs /configfs
```

詳しくは[こちら](https://qiita.com/ikwzm/items/ec514e955c16076327ce)や[こちら](https://dora.bk.tsukuba.ac.jp/~takeuchi/?%E9%9B%BB%E6%B0%97%E5%9B%9E%E8%B7%AF%2Fzynq%2FDevice%20Tree%20Overlay)を参考にさせて頂いております。


### ファームウェアのコピー

必要なものを  /lib/firmware にコピーします。

```bash
sudo mkdir -p /lib/firmware
sudo cp kv260_blinking_led.bit.bin /lib/firmware
sudo cp kv260_blinking_led.dtbo /lib/firmware
```

### overlay 

次に overlay を行います。

```bash
sudo sh -c "echo 0 > /sys/class/fpga_manager/fpga0/flags"
sudo mkdir /configfs/device-tree/overlays/full
sudo sh -c "echo -n kv260_blinking_led.dtbo > /configfs/device-tree/overlays/full/path"
```

この段階で bitstream は書き込まれ、動作を開始しています。

### 状態確認

状態を確認するには

```bash
cat /configfs/device-tree/overlays/full/status
```

でできるようで applied と表示されればよいようです。

役目を終えたファイルは削除してよいようです。

```bash
sudo rm /lib/firmware/kv260_rpu_sample.dtbo
sudo rm /lib/firmware/kv260_rpu_sample.bit.bin
```



## Device Tree Overlay の解除

```bash
sudo rmdir /configfs/device-tree/overlays/full
```

と削除すると、解除できるようです。

