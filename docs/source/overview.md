# Overview

## はじめに

  [Jelly](https://github.com/ryuz/jelly) とは、FPGA向けの MIPS-I ライクな命令セットのコアを有した
ソフトコアプロセッシングシステムで、従来マイコンで制御していた分野の
ワンチップマイコンをFPGAで置き換えるケースに向けての挑戦からスタートしました。

昨今ではXILINXのZynqシリーズのようにCPU部とロジック部を合わせもあったSoCも
台頭してきたため、より柔軟にロジック資産を活用できるプラットフォームとして進化を続けています。


## 構成


### トップディレクトリ

|ディレクトリ       |説明|
|:-----------------|:----------------|
|docs              |各種ドキュメント |
|rtl               |各種RTLソース   |
|projects          |各種プロジェクト |
|include           | ソフトウェア用インクルードファイル|
|testbench         | 各種テストベンチ|
|python            | Python関連|
|soft              | 各種ソフトウェア
|tools             | 各種ツール類


### rtl ディレクトリ

|ディレクトリ       |説明|
|:-----------------|:----------------|
|cpu               |CPUコア         |
|cache             |キャッシュメモリ |
|gpu               |GPUコア         |
|peripheral        |マイコン周辺モジュール|
|primitive         |デバイスプリミティブなモジュール|
|library           |各種ライブラリ的モジュール|
|bus               |バス変換などのモジュール|
|math              |算術計算関連|
|video             |ビデオ信号処理各種|
|image             |画像処理各種|
|misc              |その他コア|
|model             |シミュレーション用モデル|


### project ディレクトリ

|ディレクトリ       |説明|
|:-----------------|:----------------|
|spartan3e_starter          | Spartan-3E Starter Kit 用プロジェクト
|spartan3_starter           | Spartan-3 Starter Kit 用プロジェクト
|ultra96v2_udmabuf_sample   | Ultra96V2 ボード用 udmabufサンプル
|zybo_z7_udmabuf_sample     | ZYBO-Z7 ボード用 udmabufサンプル
|zybo_z7_imx219             | ZYBO-Z7 ボード用 IMX219サンプル
|zybo_z7_imx219_hdmi        | ZYBO-Z7 ボード用 IMX219+HDMIサンプル

