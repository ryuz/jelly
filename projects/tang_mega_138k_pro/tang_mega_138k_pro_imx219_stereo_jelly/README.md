# Tang Mega 138K Pro の IMX219 ステレオカメラ 自作MIPI受信版

## 概要

コマンドラインから [Tang Mega 138K Pro Dock](https://wiki.sipeed.com/hardware/en/tang/tang-mega-138k/mega-138k-pro.html) で
IMX219 MIPIカメラを2つ動かすサンプルです。

[こちら](https://rtc-lab.com/products/tang-mega-138k-pro-dock-mipi-imx219/)の変換基板を利用しています。

基板の設計データは [https://github.com/ryuz/imx219_mipi24_sipeed](https://github.com/ryuz/imx219_mipi24_sipeed) にあります。



カメラは J15 と J16 のコネクタにフレキの向きなどに注意して取り付けてください。

自家製 RISC-Vコア で Rust を利用しているのでそれらの事前インストールも必要です。

RISC-V プログラムの hex 変換で numpy インストール済みの python なども利用しますのでセットアップが必要です。

RISC-V 用 Rust のセットアップについては [こちら](/projects/kv260/kv260_jfive_simple_controller/README.md)などを参考にしてください。


## 環境

私は Windows 版の Gowin EDA を、WSL2 から利用しています。バージョンは Gowin_V1.9.11.02_SP1 を利用しています。

焼き込みには Windows版の [openFPGALoader](https://github.com/trabucayre/openFPGALoader) を利用させて頂いています。

WSLから Windows 版を利用しやすいようにパスの通ったところに下記のようなスクリプトを作っておいています。

chmod +x などのコマンドで実行権限を与えてパスの通ったところにおいてください。

パスは適用に自分の環境用に読み替えてください。

### gw_sh

```bash
#!/usr/bin/bash
/mnt/c/Gowin/Gowin_V1.9.11.02_SP1_x64/IDE/bin/gw_sh.exe $@
```

### openFPGALoader

```bash
#!/usr/bin/bash
/mnt/c/msys64/mingw64/bin/openFPGALoader.exe $@
```

## ビルド

syn ディレクトリ以下で

```
make
```

とすると 合成します。

tclスクリプトは scripts/gowin_build.tcl にあり、Makefile 内の WSLENV の指定で、環境変数を WSL から Windows に渡しています。


またこの際に、本合成に先だって jfive 以下の Rust プログラムのビルドなども行い、
メモリ周りだけ個別 .vg ファイルに合成した後に、本合成で結合しています。

そのまま合成するとなぜか RISC-V 用のメモリ推論が失敗する(RTLの記述に反してREAD_FIRSTメモリにしようとしてしまいエラーになる)為、このような流れになっています。


## 実行

```
make run
```

で、ダウンロード実行します。

## 動作


### UARTコマンド

TeraTerm などのターミナルソフトを使えば COMポートから UART 経由でコマンドが使えます。

```
help
```

と打ち込むと、コマンドヘルプが出ます。

たとえば IMX219 のアナログゲインは 0x0157 番地なので

```
i2cw16 0x0157 100
```

などと打ち込めばゲイン調整ができます。

