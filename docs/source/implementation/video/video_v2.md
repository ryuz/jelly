# Video Ver2

## 概要

Ver2 は `jelly2_` 系の Video 実装群です。

## 実装配置

- `rtl/v2/video`

## 主要モジュール

- `jelly2_video_format_regularizer.sv`
- `jelly2_video_filter2d.sv`
- `jelly2_video_demosaic_acpi.sv`
- `jelly2_video_overlay_bram.sv`
- `jelly2_video_rendezvous.sv`
- `jelly2_mipi_csi2_rx.sv`
- `jelly2_mipi_rx_lane.sv`

## 利用指針

- 画像処理ブロックは `rtl/v2/image` 側と組み合わせて使う前提の設計が多いです。
- MIPI 取り込みから DMA までを同世代で揃えると検証工数を抑えられます。
