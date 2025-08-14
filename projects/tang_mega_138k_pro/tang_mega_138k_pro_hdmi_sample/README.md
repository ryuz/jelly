# Tang Mega 138K Pro の IMX219 の HDMI(DVI)出力確認

## 概要

コマンドラインから [Tang Nano 9k](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html) で
HDMIコネクタを使った DVI 出力確認をするものです。

主に tcl スクリプトで SystemVerilog をビルドして実行できます。


## 環境

私は Windows 版の Gowin EDA を、WSL2 から利用しています。

焼き込みには Windows版の [openFPGALoader](https://github.com/trabucayre/openFPGALoader) を利用させて頂いています。

WSLから Windows 版を利用しやすいようにパスの通ったところに下記のようなスクリプトを作っておいています。

詳しくは[こちら](https://blog.rtc-lab.com/entry/2025/08/05/201839)をご覧ください。

chmod +x などのコマンドで実行権限を与えてパスの通ったところにおいてください。

パスは適用に自分の環境用に読み替えてください。


### gw_sh

```bash
#!/usr/bin/bash
/mnt/c/Gowin/Gowin_V1.9.11.03_x64/IDE/bin/gw_sh.exe $@
```

### openFPGALoader

```bash
#!/usr/bin/bash
/mnt/c/msys64/mingw64/bin/openFPGALoader.exe $@
```

## ビルド


```
make
```

で合成します。

tclスクリプトは scripts/gowin_build.tcl にあり、Makefile 内の WSLENV の指定で、環境変数を WSL から Windows に渡しています。


## 実行

```
make run
```

で、ダウンロード実行します。


WSLから Windows 版の proglamable_cli を使いたい場合は、PROGRAMMER_CLI_OPTIONS 環境変数を自分の環境に合わせて設定した後に

```
make run_wsl
```

とすれば実行できるようにしています。
