# Tang Nano 4k の LEDチカチカ


## 概要
コマンドラインから [Tang Nano 4k](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-4K/Nano-4K.html) で
LEDチカチカをするものです。

主に tcl スクリプトで SystemVerilog をビルドして、実行することのサンプルです。


## 環境

私は Windows 版の Gowin EDA を、WSL2 から利用しています。

焼き込みには Windows版の [openFPGALoader](https://github.com/trabucayre/openFPGALoader) を利用させて頂いています。

WSLから Windows 版を利用しやすいようにパスの通ったところに下記のようなスクリプトを作っておいています。

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

