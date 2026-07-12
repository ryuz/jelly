# プロジェクト全体像

## はじめに

Jelly は FPGA 上でのリアルタイムコンピューティングを目指すモジュール群です。

開発初期は MIPS-I 互換ソフトコアと RTOS 実行基盤を中心に構成されていましたが、現在は SoC 上の CPU ソフトウェア資産と RTL 資産を柔軟に組み合わせる実装基盤へ拡張されています。

## リポジトリ構成

トップディレクトリの代表的な役割は次の通りです。

|ディレクトリ|説明|
|:--|:--|
|`docs`|ドキュメント|
|`projects`|ボード別サンプル・実験プロジェクト|
|`rtl`|RTL ソース|
|`include`|C/C++ 向けヘッダ|
|`python`|Python 関連コード|
|`testbench`|テストベンチ|
|`tools`|補助ツール|

## RTL の実装世代

- Ver1: Verilog-2001 世代の資産
- Ver2: SystemVerilog + Verilator を主軸とした現行資産
- Ver3: interface/package 等を積極活用する次世代資産

カテゴリ別の実装詳細は [実装リファレンス](implementation/index.md) を参照してください。

## 関連トピック

- Real-time OS 連携: [HOS-V4a](https://github.com/ryuz/hos-v4a)
- Neural Network 活用: [BinaryBrain](https://github.com/ryuz/BinaryBrain)
- デモ動画
	- [Real-Time Deep Neural Network](https://youtu.be/f78qxm15XYA)
	- [Real-Time GPU](https://youtu.be/vl-lhSOOlSk)
	- [IMX219 1000fps](https://youtu.be/APEWDrVak-4)
	- [IMX219+OLED](https://youtu.be/wGRhw9bbiik)
