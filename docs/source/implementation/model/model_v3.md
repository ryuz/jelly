# Model Ver3

## 概要

Ver3 の Model カテゴリは、検証環境でバスアクセスやストリーム入出力を再現するためのモデルを提供します。

## 実装配置

- `rtl/v3/model`

## 代表モジュール

- `jelly3_model_axi4_m.sv`
  - AXI4 マスタ側のトランザクションモデルです。
- `jelly3_model_axi4_s.sv`
  - AXI4 スレーブ側の応答モデルです。
- `jelly3_model_axi4l_m.sv`
  - AXI4-Lite マスタ側のトランザクションモデルです。
- `jelly3_model_axi4s_m.sv`
  - AXI4-Stream 送出側のモデルです。
- `jelly3_model_axi4s_dump.sv`
  - AXI4-Stream の観測結果をダンプして解析しやすくする補助モデルです。
- `jelly3_model_img_dump.sv`
  - 画像処理パイプラインの出力をダンプするモデルです。

## 利用方針

- サブモジュールや派生モデルは用途依存が強いため、本章では代表的な入出力モデルに絞って記載します。
- 実機接続前の単体検証では、まず AXI4/AXI4-Lite モデルで制御面を固める流れを推奨します。
