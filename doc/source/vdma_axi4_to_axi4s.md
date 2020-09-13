# Video read DMA(AXI4 to AXI4-Stream)

## 概要

AXI4 メモリバスから読み出して AXI4-Stream Video を出力


## レジスタ仕様

アドレスはWISHBONEのワードアドレス。
レジスタ幅や初期値は parameter 指定で変更可能。


| register name      |addr|R/W|size|description                   |
|:------------------ |:--:|:-:|:--:|:-----------------------------|
|CORE_ID       |0x00|RO | 32 | core ID     |
|CORE_VERSION  |0x01|RO | 32 | core verion |
|CTL_CONTROL   |0x04|RW |  3 | bit[0]:有効化<br>bit[1]:パラメータ更新予約(自動クリア)<br>bit[2]:ワンショット転送|
|CTL_STATUS    |0x05|RO |  1 |DMA動作中に1になる|
|PARAM_ADDR    |0x08|RW | -- |読み出しアドレス|
|PARAM_STRIDE  |0x09|RW | -- |1ラインのストライド(バイト単位)|
|PARAM_WIDTH   |0x0a|RW | -- |画像幅(ピクセル単位)|
|PARAM_HEIGHT  |0x0b|RW | -- |画像高さ(ピクセル単位)|
|PARAM_SIZE    |0x0c|RW | -- |転送ピクセルサイズ(ピクセル単位)|
|PARAM_AWLEN   |0x0f|RW |  8 |１回の最大バースト転送サイズ-1(バス幅単位)|


## 動作説明

CTL_CONTROL の bit0 が1の時に画像データの読出しを行う。CTL_CONTROL の bit2 が1の場合は、PARAM_SIZE分転送すると停止する(bit0は自動クリア)。
そうでない場合は画像が来るたびに繰り返し転送を行う。
CTL_CONTROL の bit1 が1の時は転送開始や繰り返しのタイミングでパラメータが更新される。

PARAM_SIZE は PARAM_WIDTH×PARAM_HEIGHT のサイズである必要がある。