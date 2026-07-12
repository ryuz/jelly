# Video Ver3

## 概要

Ver3 は `jelly3_` 系の Video 実装群です。MIPI 周辺とフォーマット整形を中心に拡張しています。

## 実装配置

- `rtl/v3/video`

## 主要モジュール

- `jelly3_video_format_regularizer.sv`
- `jelly3_video_format_regularizer_core.sv`
- `jelly3_video_pattern_generator.sv`
- `jelly3_video_shrink.sv`
- `jelly3_video_frame_histry_mem_core.sv`
- `jelly3_mipi_csi2_rx_packet_2lane.sv`
- `jelly3_mipi_csi2_tx_packet_2lane.sv`

## 移行観点

- `jelly3_` 系 image モジュールと接続する場合、インタフェース設計の統一メリットが大きいです。
- 新規案件では Ver3 の採用を優先し、既存 Ver2 系は段階移行を推奨します。
