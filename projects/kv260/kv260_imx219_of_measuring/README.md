# Kria KV260 で Raspberry Pi Camera Module V2 (Sony IMX219) によるオプティカルフロー計測

## 概要

Kria KV260 で Raspberry Pi Camera Module V2 (Sony IMX219) を用いてリアルタイムオプティカルフロー計測を行うサンプルです。Lucas-Kanade法を用いた動き検出とトラッキング機能を実装しています。

## 機能

- IMX219カメラ(1000fps)からのリアルタイム画像取得
- FPGA回路による 1ms 以下の低遅延 Lucas-Kanadeオプティカルフロー計算
- 指定領域内での動きベクトル計測 ＆ DACによるアナログ出力
- リアルタイムトラッキング表示
- 計測データのCSV出力

## 環境

### PC環境

vivado2023.2 を用いております。

### KV260環境

[認定Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html) 環境にて試しております。

```
image       : iot-kria-classic-desktop-2004-x03-20211110-98.img
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

projects/kv260/kv260_imx219_of_measuring/syn/vivado2023.2

に移動して Vivado から kv260_imx219_of_measuring.xpr を開いてください。

最初に BlockDesign を tcl から再構成する必要がります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている i_design_1 を手動で削除してから、design_1.tcl を実行しても同じことができるはずです。

design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば

kv260_imx219_of_measuring.runs/impl_1

に kv260_imx219_of_measuring.bit が出来上がります。

### KV260 でPSソフトをコンパイルして実行

projects/kv260/kv260_imx219_of_measuring/app の内容一式と先ほど合成した kv260_imx219_of_measuring.bit を、KV260 の Ubuntu で作業できる適当なディレクトリにコピーします。bitファイルも同じ app ディレクトリに入れてください。

KV260 側では Ubuntu が起動済みで ssh などで接続ができている前提ですので scp や samba などでコピーすると良いでしょう。app に関しては KV260 から git で clone することも可能です。

この時、

- OpenCV や bootgen など必要なツールがインストールできていること
- ssh ポートフォワーディングなどで、PCに X-Window が開く状態にしておくこと
- /dev/uio や /dev/i2c-6 などのデバイスのアクセス権が得られること
- sudo 権限のあるユーザーで実行すること

などの下準備がありますので、ブログなど参考に設定ください。

問題なければ、app をコピーしたディレクトリで

```
make all
```

と実行すれば kv260_imx219_of_measuring.out という実行ファイルが生成されます。

ここで

```
make run
```

とすると、Device Tree overlay によって、bit ファイルの書き込みなどを行った後にプログラムが起動し、ホストPCの方の X-Window に、カメラ画像とオプティカルフロー計測結果が表示されるはずです。

なお、Device Tree overlay のロード／アンロードは

```
make load
make unload
```

といったコマンドで実施可能です。


## 操作方法

### マウス操作
- 画像上をクリック：トラッキング対象位置の設定

### キーボード操作
- 'p': カメラパラメータ表示
- 'h': 水平フリップ切り替え
- 'v': 垂直フリップ切り替え
- 'a': トラッキング位置を計測領域中心にリセット
- 's': 計測データをCSVファイルに保存 (data.csv, line_time.csv)
- 'd': 現在の画像をPNG形式で保存 (img_dump.png)
- 'r': 連続画像記録 (record/ディレクトリに保存)
- 'ESC' または 'q': 終了

### トラックバー
- scale: 表示倍率
- fps: フレームレート
- exposure: 露光時間
- a_gain: アナログゲイン
- d_gain: デジタルゲイン
- gauss: ガウシアンフィルタレベル
- x, y: 計測領域中心位置
- w, h: 計測領域サイズ

## 計測データ出力

's'キーを押すことで以下のデータがCSV形式で出力されます：

- data.csv: オプティカルフローの X,Y 成分の時系列データ
- line_time.csv: ライン同期タイミングデータ

## 画面表示

プログラム実行中は以下の画面が表示されます：

1. **img**: メイン画像表示（計測領域とトラッキング位置を重畳表示）
2. **graph**: オプティカルフローのX,Y成分の時系列グラフ（緑:X成分、青:Y成分）
3. **x-y**: オプティカルフローベクトルの軌跡表示

## ハードウェア構成

本プロジェクトは以下のハードウェア機能を実装しています：

- **MIPI CSI-2受信**: IMX219からの高速画像データ受信
- **画像前処理**: ガウシアンフィルタによるノイズ除去
- **Lucas-Kanadeオプティカルフロー**: ハードウェア実装による高速計算
- **DMA転送**: 高効率な画像データ転送
- **リアルタイム処理**: 1000fpsでの動き検出対応

## 参考情報

- 作者ブログ記事
    - [Zybo Z7 への Raspberry Pi Camera V2 接続(MIPI CSI-2受信)](https://rtc-lab.com/2018/04/29/zybo-rpi-cam-rx/)
    - [Zybo Z7 への Raspberry Pi Camera V2 接続 (1000fps動作)](https://rtc-lab.com/2018/05/06/zybo-rpi-cam-1000fps/)

- [https://github.com/lvsoft/Sony-IMX219-Raspberry-Pi-V2-CMOS](https://github.com/lvsoft/Sony-IMX219-Raspberry-Pi-V2-CMOS)
    - Raspberry Pi Camera Module V2 の各種情報（IMX219のデータシートあり)
- [https://www.raspberrypi.org/forums/viewtopic.php?t=160611&start=25](https://www.raspberrypi.org/forums/viewtopic.php?t=160611&start=25)
    - 各種情報。[回路図](https://cdn.hackaday.io/images/5813621484631479007.jpg)の情報あり

## 技術仕様

- **オプティカルフロー算法**: Lucas-Kanade法
- **計測精度**: サブピクセル精度
- **最大フレームレート**: 1000fps (640x130モード)
- **計測領域**: 可変サイズ・位置設定可能
- **データ出力**: CSV形式での時系列データ保存
  