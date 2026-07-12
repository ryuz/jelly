# DMA Ver3

## 概要

Ver3 は `jelly3_` 系 DMA 実装です。制御プレーンや型の整理を進めた世代を想定しています。

## 実装配置

- `rtl/v3/dma`

## 主要モジュール

- `jelly3_buffer_manager.sv`
- `jelly3_buffer_allocator.sv`
- `jelly3_dma_stream_write.sv`
- `jelly3_dma_video_write.sv`

## 移行観点

- Ver2 までのパラメータ設計と比較して、Ver3 は他の `jelly3_` ライブラリとの接続一貫性を優先します。
- 新規実装は Ver3 を優先し、Ver1/Ver2 資産は段階移行を推奨します。
