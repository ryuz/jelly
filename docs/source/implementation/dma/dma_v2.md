# DMA Ver2

## 概要

Ver2 は SystemVerilog ベースの `jelly2_` 系 DMA 実装です。

## 実装配置

- `rtl/v2/dma`

## 主要モジュール

- `jelly2_buffer_manager.sv`
- `jelly2_buffer_allocator.sv`
- `jelly2_dma_stream_write.sv`
- `jelly2_dma_stream_read.sv`
- `jelly2_dma_video_write.sv`
- `jelly2_dma_video_read.sv`

## 利用指針

- 既存の Ver1 レジスタ体系を引き継ぐ構成が多く、置き換え時のソフト修正量を抑えやすいです。
- Video/Image パイプラインとの接続では `rtl/v2/video` と同時に版を揃える運用を推奨します。
