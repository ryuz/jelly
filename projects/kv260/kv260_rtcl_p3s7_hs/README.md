# Kria KV260 で PYTHON300 + Spartan7 センサー D-PHY 独自プロトコル高速版カメラを動かす

注：本 README は AI で自動生成しているため、誤りを含む可能性があります。


## 概要

Kria KV260 で [グローバルシャッターMIPI高速度カメラ](https://rtc-lab.com/products/rtcl-cam-p3s7-mipi/)(設計は[こちら](https://github.com/ryuz/rtcl-p3s7-mipi))を動かすサンプルです。

このプロジェクトは、PYTHON300 センサー + Spartan-7 FPGA を搭載したカメラモジュールを KV260 に接続し、D-PHY 上で独自プロトコルを用いた高速画像伝送を行います。MIPI-CSI規格を使わずに独自プロトコルで伝送することで、画像1フレームを1パケットとして転送し、伝送帯域を有効活用して高速度撮影を実現しています。

PYTHON300 センサーは 640×480 で 815fps、画像サイズを小さくすれば 1000fps を超える撮影が可能な高性能グローバルシャッターセンサーです。

## 環境

### PC環境

Vivado 2023.2 を用いております。

### KV260環境

[認定Ubuntu](https://japan.xilinx.com/products/design-tools/embedded-software/ubuntu.html) 環境にて試しております。

```
Description : Ubuntu 22.04 LTS  
kernel      : xilinx-zynqmp  
```

### OpenCV

```bash
sudo apt update
sudo apt install libopencv-dev
```

## 動かし方

### gitリポジトリ取得

```bash
git clone https://github.com/ryuz/jelly.git
```

で一式取得してください。

### PC側の Vivado で bit ファイルを作る

#### TCL ビルド (推奨)

Vivado が使えるように

```bash
source /tools/Xilinx/Vivado/2023.2/settings64.sh
```

したのちに

```bash
cd projects/kv260/kv260_rtcl_p3s7_hs/syn/tcl
make
```

とすると bit ファイルが生成されます。

#### GUI 版

`projects/kv260/kv260_rtcl_p3s7_hs/syn/vivado2023.2/kv260_rtcl_p3s7_hs.xpr`

に Vivado GUI 用のプロジェクトがあるので、Vivado の GUI から開いてご利用ください。

最初に BlockDesign を tcl から再構成する必要があります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある `update_design.tcl` を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている design_1 を手動で削除してから、`design_1.tcl` を実行しても同じことができるはずです。

design_1 が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば

`kv260_rtcl_p3s7_hs.runs/impl_1/kv260_rtcl_p3s7_hs.bit`

が出来上がります。

### KV260 でPSソフトをコンパイルして実行

`projects/kv260/kv260_rtcl_p3s7_hs/app` の内容一式と先ほど合成した `kv260_rtcl_p3s7_hs.bit` を、KV260 の Ubuntu で作業できる適当なディレクトリにコピーします。bitファイルも同じ app ディレクトリに入れてください。

KV260 側では Ubuntu が起動済みで ssh などで接続ができている前提ですので scp や samba などでコピーすると良いでしょう。app に関しては KV260 から git で clone することも可能です。

この時、以下の下準備が必要です：

- OpenCV や bootgen など必要なツールがインストールできていること
- ssh ポートフォワーディングなどで、PCに X-Window が開く状態にしておくこと
- /dev/uio や /dev/i2c-6 などのデバイスのアクセス権が得られること
- sudo 権限のあるユーザーで実行すること

などの下準備がありますので、ブログなど参考に設定ください。

問題なければ、app をコピーしたディレクトリで

```bash
make all
```

と実行すれば `kv260_rtcl_p3s7_hs.out` という実行ファイルが生成されます。

ここで

```bash
make run
```

とすると、Device Tree overlay によって、bit ファイルの書き込みなどを行った後にプログラムが起動し、ホストPCの方の X-Window に、カメラ画像が表示されるはずです。

### コマンドラインオプション

実行ファイルは以下のオプションを受け付けます：

```bash
./kv260_rtcl_p3s7_hs.out -width 256 -height 256
```

- `-width <値>` : 画像幅を指定（16の倍数、最小16）
- `-height <値>` : 画像高さを指定（最小1）

### Device Tree overlay のロード／アンロード

Device Tree overlay のロード／アンロードは

```bash
make load      # ロード
make unload    # アンロード
```

といったコマンドで実施可能です。

### その他の実行方法

#### Rust版の実行

```bash
make run_rust
```

#### gRPCサーバーの起動

```bash
make server
```

## シミュレーション

`projects/kv260/kv260_rtcl_p3s7_hs/sim` 以下にシミュレーション環境を作っています。

該当ディレクトリに移動して make と実行することで、シミュレーションが動きます。

.vcd ファイルとして波形が生成されるので、gtkwave などの波形ビューワーで確認ください。

## カメラモジュールの仕様

本プロジェクトで使用するカメラモジュールの仕様：

| 項目 | 仕様 |
|------|------|
| イメージセンサー | オンセミコンダクター PYTHON300<br>モノクロ：NOIP1SN0300A-QTI<br>カラー：NOIP1SN0300A-QTI |
| FPGA | AMD Spartan-7 (XC7S6-2FTGB196C) |
| 解像度 | 640×480 (VGA) |
| 最大フレームレート | 815 fps (Zero ROT mode) |
| 画素サイズ | 4.8μm × 4.8μm |
| シャッター方式 | グローバルシャッター |
| MIPIコネクタ | Raspberry PI 互換 15pin コネクタ<br>差動信号2レーン (各最大1250Mbps)<br>I2C信号線、GPIO線 x 2bit、3.3V給電 |
| 汎用I/O | PMOD仕様コネクタ x 1 |
| JTAGコネクタ | Xilinx標準仕様(2×7 2mmピッチ) x 1 |

## システム特徴

- **独自プロトコル**: MIPI-CSI規格を使わず、D-PHY上で独自プロトコルで高速伝送
- **高速度撮影**: 画像1フレームを1パケットとして転送することで伝送帯域を有効活用
- **グローバルシャッター**: 動きの速い被写体でも歪みなく撮影可能
- **低遅延**: FPGAベースの処理による低遅延画像処理
- **同期撮影**: 外部照明やトリガー信号との同期撮影が可能

## 各種設定

FPGAの内部動作や、イメージセンサーのSPIでアクセスするレジスタはI2Cから制御できるようにしております。

### FPGA設定

I2C経由で 16bitアドレス 16bit データの読み書きが可能で、以下のレジスタが操作できます。

|   Addr | 名称                 | Access | リセット値    | Bits/説明                                      |
|--------|----------------------|--------|--------------|-----------------------------------------------|
| 0x0000 | CORE_ID              | RO     | 0x527A       | [15:0]=0x527A, 識別子                         |
| 0x0001 | CORE_VERSION         | RO     | 0x0100       | [15:0]=0x0100, バージョン                     |
| 0x0010 | RECV_RESET           | R/W    | 0x0001       | [0]=1: 受信系リセット                         |
| 0x0020 | ALIGN_RESET          | R/W    | 0x0001       | [0]=1: アライメント部リセット                 |
| 0x0022 | ALIGN_PATTERN        | R/W    | 0x03A6       | [9:0]: パターン値                              |
| 0x0028 | ALIGN_STATUS         | RO     | -            | [1]=エラー, [0]=完了                           |
| 0x0080 | DPHY_CORE_RESET      | R/W    | 0x0001       | [0]=1: D-PHY コアリセット                     |
| 0x0081 | DPHY_SYS_RESET       | R/W    | 0x0001       | [0]=1: D-PHY SYSリセット                      |
| 0x0088 | DPHY_INIT_DONE       | RO     | -            | [0]=1: D-PHY 初期化完了                       |


## 応用例

### マルチスペクトル撮影

グローバルシャッターカメラでは照明とシャッターを同期させた高速度撮影が容易です。複数色のLEDを用意して発光パターンを変えながら撮影することで、マルチスペクトル計測が可能です。

### ビジュアルフィードバック

1ms級の低遅延での非接触画像認識により、以下のような応用が可能です：
- 非接触での振動計測による故障検知／予知
- 振動環境下での画像認識  
- 振動フィードバックによる制振制御
- ランダムに動くものの把持
- 遅延なく人間の動きに追従するアシストロボ

### 同期撮影

FPGAから生成したパルスで同期撮影が可能です。超高速での照明変化と同期してシャッターを切ることで、通常のカメラでは不可能な特殊撮影が実現できます。

## 参考情報

- [作者ブログ記事](https://rtc-lab.com/products/rtcl-cam-p3s7-mipi/)
- [PYTHON300 データシート](https://www.onsemi.jp/products/sensors/image-sensors/python300)
- [カメラモジュール設計リポジトリ](https://github.com/ryuz/rtcl-p3s7-mipi)
- [Kria KV260 ビジョン AI スターター キット](https://www.amd.com/ja/products/system-on-modules/kria/k26/kv260-vision-starter-kit.html)

