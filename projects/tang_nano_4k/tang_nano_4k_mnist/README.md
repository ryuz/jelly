# Tang Nano 4k の MNIST 認識 (LUT-Network)


## 概要

[Tang Nano 4k](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-4K/Nano-4K.html) でMNIST認識を動かしてみるサンプルです。

[BinaryBrain](https://github.com/ryuz/BinaryBrain)の[こちら](https://github.com/ryuz/BinaryBrain/blob/master/samples/python/mnist/MnistDifferentiableLut4Simple.ipynb)のサンプルを使って学習させた LUT-Network を動かすデモです。


## 環境

私は Windows 版の Gowin EDA を、WSL2 から利用しています。

焼き込みには Windows版の [openFPGALoader](https://github.com/trabucayre/openFPGALoader) を利用させて頂いています。

WSL2 から Windows 版を利用できるようにパスの通ったところに下記のようなスクリプトを作っておいています。

chmod +x などのコマンドで実行権限を与えてパスの通ったところにおいてください。

パスは適用に自分の環境用に読み替えてください。

### gw_sh

```bash
#!/usr/bin/bash
/mnt/c/Gowin/Gowin_V1.9.9Beta-4/IDE/bin/gw_sh.exe $@
```

### openFPGALoader

```bash
#!/usr/bin/bash
/mnt/c/openFPGALoader/bin/openFPGALoader.exe $@
```


## ビルド

ビルドには [Sipeedさんのサンプル](https://github.com/sipeed/TangNano-4K-example) をサブモジュールとして利用しています。

サブモジュールが取得できていない場合は、例えば下記のようなコマンドで取得しておいてください。

```
git submodule update --init --recursive
```


ビルドは projects/tang_nano_4k/tang_nano_4k_mnist/syn ディレクトリに移動して

```
make
```

とすると合成や配置配線を行います。

tclスクリプトは scripts/gowin_build.tcl にあり、Makefile 内の WSLENV の指定で、環境変数を WSL から Windows に渡しています。


## 実行

```
make run
```

で、openFPGALoader を使ったダウンロード実行します。


