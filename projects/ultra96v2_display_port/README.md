# Ultra96V2 で DisplayPort を試すサンプル


## 概要

Ultra96V2 で DisplayPort を実験中です。未だ不安定です。


## 事前準備

### 環境
環境は下記の通りです。

- [Ultra96V2](https://www.avnet.com/wps/portal/japan/products/product-highlights/ultra96/)
-  iwkzm氏の [Debianブートイメージ 2019.2版](https://qiita.com/ikwzm/items/92221c5ea6abbd5e991c)
- Vivado 2019.2

Debianイメージは一度起動SDを作ってしまえば Vivado だけでもいろいろできるのが素敵です。

### Ultra96v2側の準備

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

/projects/ultra96v2_display_port/

以下が今回のプロジェクトです。


## PL用bitstreamの作成

PS用のbitstreamは PC(WindowsやLinuxなど)で Vivado を使って行います。

Vivado のプロジェクトは

/projects/ultra96v2_display_port/syn/vivado2019.2/ultra96v2_display_port.xpr

にありますので Vivado で開いてください。

最初に BlockDesign を tcl から再構成する必要がります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている i_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。

design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば
ultra96v2_display_port.bit が出来上がります。

このファイルを projects/ultra96v2_display_port/app にコピーしておいてください。


## ソフト側の作成と実行
  Ultra96V2側のソフトの開発です。
  projects/ultra96v2_display_port/app を Ultra96 のどこか適当な箇所にコピーします。
  Ultra96V2側の作業は Debian のブートイメージで起動したあと、常に起動したまま行うことが可能で、運用したままPLとソフトをアップデートすることも可能なのがこのブートイメージの素晴らしいところです。

  Ultra96V2 の debian でも git は動きますので、こちらでも clone する手があります。
  (なお、この app ディレクトリ以下は VS code Remote Development を使ってセルフコンパイル開発してそのままpushしています。)

### 動かしてみる

sudoできるユーザーで app ディレクトリに移動してください。
```
make run
```
とすればひとまず動くように作っております。
途中、sudo コマンドを使っているのでパスワードを聞かれると思いますが入力ください。
DeviceTree overlay や uio へのアクセスの為にルート権限が必要なためです。



