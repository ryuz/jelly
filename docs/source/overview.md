# Overview

## はじめに

  [Jelly](https://github.com/ryuz/jelly) とは、FPGA上にてリアルタイムコンピューティングを行う為のプラットフォームを目指している、各種モジュール群です。

  もともとはFPGA向けの MIPS-I ライクな命令セットのコアを有したソフトコアプロセッシングシステムで、Real-time OS を動かすことからスタートしたプロジェクトですが、昨今ではXILINXのZynqシリーズのようにCPU部とロジック部を合わせもあったSoCも
台頭してきたため、より柔軟にRTLロジック資産(Verilog)と、CPU資産(C/C++/Pythonなど)を組み合わせて、エッジでのリアルタイムコンピューティングを目指しつつIoT連携できるプラットフォームとして進化を続けています。

　FPGAと言いつつかなり Xilinx 専用になっている点はご容赦ください。RTL自体は汎用なものも多いです。


## 構成


### トップディレクトリ

|ディレクトリ       |説明|
|:-----------------|:----------------|
|docs              | 各種ドキュメント |
|projects          | 各種プロジェクト |
|rtl               | 各種RTLソース   |
|include           | C/C++用インクルードファイル|
|python            | Python関連|
|testbench         | 各種テストベンチ|
|tools             | 各種ツール類


### rtl ディレクトリ

|ディレクトリ       |説明|
|:-----------------|:-------------------|
|library           |各種ライブラリ的モジュール|
|bus               |バス変換などのモジュール|
|math              |算術計算関連|
|video             |ビデオ信号処理各種|
|image             |画像処理各種|
|gpu               |Real-time GPU |
|peripheral        |マイコン周辺モジュール|
|primitive         |デバイスプリミティブなモジュール|
|misc              |その他コア|
|model             |シミュレーション用モデル|
|cpu               |CPUコア(MIPS-I互換) Real-time OS 対応|
|cache             |キャッシュメモリ |
|legacy            |過去の遺物(新コアに移行前の旧RTL置き場)|


### project ディレクトリ


|ディレクトリ       |説明|
|:-----------------|:----------------|
|ultra96v2_udmabuf_sample   | Ultra96V2 ボード用 udmabufサンプル
|zybo_z7_udmabuf_sample     | ZYBO-Z7 ボード用 udmabufサンプル
|zybo_z7_imx219             | ZYBO-Z7 ボード用 IMX219サンプル
|zybo_z7_imx219_hdmi        | ZYBO-Z7 ボード用 IMX219+HDMIサンプル
|spartan3e_starter          | Spartan-3E Starter Kit 用プロジェクト
|spartan3_starter           | Spartan-3 Starter Kit 用プロジェクト

その他未整備のプロジェクト各種


## Real-time OS について

拙作の [HOS-V4a](https://github.com/ryuz/hos-v4a) にて、上記の MPIS互換コア、MicroBlaze、Cortex-R5 などに対応中です。


## Real-time Neural Network について

微分可能回路記述に基づくLUT 直接学習による深層学習モデル(LUT-Network)用の学習環境として開発中の[BinaryBrain](https://github.com/ryuz/BinaryBrain)もJellyの画像処理コンポーネントを用いてCNNを構成しており、そのまま当プラットフォームに組み込むことが可能です(NN部の入出力自体は AXI4-Stream なので汎用的です)。

メモリを介さずにリアルタイムに推論結果が出力可能であり、本プラットフォーム上で効果的に利用することが可能です。


## Jellyを使ったシステムのデモ動画

- [Real-Time Deep Neural Network](https://youtu.be/f78qxm15XYA)
- [Real-Time GPU](https://youtu.be/vl-lhSOOlSk)
- [IMX219 1000fps](https://youtu.be/APEWDrVak-4)
- [IMX219+OLED](https://youtu.be/wGRhw9bbiik)


