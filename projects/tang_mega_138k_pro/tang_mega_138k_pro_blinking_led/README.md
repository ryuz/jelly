# Tang Mega 138K Pro の LEDチカチカ


## 概要
コマンドラインから [Tang Mega 138K Pro Dock](https://wiki.sipeed.com/hardware/en/tang/tang-mega-138k/mega-138k-pro.html) で
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
/mnt/c/Gowin/Gowin_V1.9.11.01_x64/IDE/bin/gw_sh.exe $@
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

