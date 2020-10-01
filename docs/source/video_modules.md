# Video 関連

/rtl/video 以下にあるモジュール




## jelly_video_parameter_update

### 概要

frame start を検出してパラメータ更新信号を出す


### レジスタ仕様

アドレスはWISHBONEのワードアドレス。
レジスタ幅や初期値は parameter 指定で変更可能。


| register name      |addr|R/W|size|description                   |
|:------------------ |:--:|:-:|:--:|:-----------------------------|
|CORE_ID             |0x00|RO|32| core ID     |
|CORE_VERSION        |0x01|RO|32| core verion |
|CONTROL             |0x04|RW| 2| bit[0]:更新予約<br>bit[1]:更新継続|
|INDEX               |0x05|RO|--| パラメータ受付毎にインクリメント|
|FRAME_COUNT         |0x06|RO|--| フレーム数カウント |


### 動作説明

各画像処理コアで処理途中にパラメータが変化すると不整合を起こすケースで次フレームを待ってパラメータ更新する機能があるものがあるが、コア内の整合性しか取れない。
本コアは、さらに画像処理コア間で不整合を起こさないために、後続コアに一斉に更新許可を出すのに用いる。


## jelly_video_format_regularizer

### 概要

AXI4-Stream Video を指定フォーマットに正規化する

### レジスタ仕様

アドレスはWISHBONEのワードアドレス。
レジスタ幅や初期値は parameter 指定で変更可能。


| register name      |addr|R/W|size|description                   |
|:------------------ |:--:|:-:|:--:|:-----------------------------|
|CORE_ID         |0x00|RO|32| core ID     |
|CORE_VERSION    |0x01|RO|32| core verion |
|CTL_CONTROL     |0x04|RW| 2| bit[0]:有効化<br>bit[1]:パラメータ更新予約(自動クリア)|
|CTL_STATUS      |0x05|RO| 1| DMA動作中に1になる|
|CTL_INDEX       |0x07|RO|--| パラメータ受付毎にインクリメント|
|CTL_SKIP        |0x08|RW| 1| 停止時に入力を堰き止めずに捨てる|
|CTL_FRM_TIMER_EN|0x0a|RW| 1| フレームタイマー有効|
|CTL_FRM_TIMEOUT |0x0b|RW|--| タイマ有効時に指定時間フレームが来なければタイムアウトして疑似フレームを生成|
|PARAM_WIDTH     |0x10|RW|--| 画像幅 |
|PARAM_HEIGHT    |0x11|RW|--| 画像高さ |
|PARAM_FILL      |0x12|RW|--| パディング時の画素値 |
|PARAM_TIMEOUT   |0x13|RW|--| フレーム転送中のデータが指定時間途切れるとタイムアウト |


### 動作説明

主に画像入力デバイスの突然の切断やデータ欠け、フォーマット不一致などにより後段のDMAの転送データ数が合わずにデッドロックをおこすなどを防止する目的のものである。



## jelly_vin_axi4s

ビデオ入力を AXI4 Stream video に変換

## jelly_vout_axi4s

AXI4 Stream video をビデオ出力に変換

## jelly_vsync_generator

ビデオ出力用の同期信号生成


## jelly_dvi_tx

DVI出力コア


## jelly_mipi_csi2_rx

MIPI-CSI2 の受信コア


## jelly_hdmi_rx

HDMI 受信コア







## jelly_vdma_axi4s_to_axi4

Video write DMA(AXI4-Stream to AXI4)

### 概要

AXI4-Stream Video を AXI4 メモリバスに書き込み転送を行う


### レジスタ仕様

アドレスはWISHBONEのワードアドレス。
レジスタ幅や初期値は parameter 指定で変更可能。


| register name      |addr|R/W|size|description                   |
|:------------ |:--:|:-:|:--:|:-----------------------------|
|CORE_ID       |0x00|RO | 32 | core ID     |
|CORE_VERSION  |0x01|RO | 32 | core verion |
|CTL_CONTROL   |0x04|RW |  3 | bit[0]:有効化<br>bit[1]:パラメータ更新予約(自動クリア)<br>bit[2]:ワンショット転送|
|CTL_STATUS    |0x05|RO |  1 |DMA動作中に1になる|
|PARAM_ADDR    |0x08|RW | -- |書き込みアドレス|
|PARAM_STRIDE  |0x09|RW | -- |1ラインのストライド(バイト単位)|
|PARAM_WIDTH   |0x0a|RW | -- |画像幅(ピクセル単位)|
|PARAM_HEIGHT  |0x0b|RW | -- |画像高さ(ピクセル単位)|
|PARAM_SIZE    |0x0c|RW | -- |転送ピクセルサイズ(ピクセル単位)|
|PARAM_AWLEN   |0x0f|RW |  8 |１回の最大バースト転送サイズ-1(バス幅単位)|


### 動作説明

CTL_CONTROL の bit0 が1の時に画像データが来ると転送を行う。CTL_CONTROL の bit2 が1の場合は、PARAM_SIZE 分転送すると停止する(bit0は自動クリア)。
そうでない場合は画像が来るたびに繰り返し転送を行う。
CTL_CONTROL の bit1 が1の時は転送開始や繰り返しのタイミングでパラメータが更新される。

PARAM_SIZE は PARAM_WIDTH×PARAM_HEIGHT の倍数である必要があるが、設定次第で複数フレームの一括記録が可能である。


## jelly_vdma_axi4_to_axi4s

Video read DMA(AXI4 to AXI4-Stream)


### 概要

AXI4 メモリバスから読み出して AXI4-Stream Video を出力


### レジスタ仕様

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


### 動作説明

CTL_CONTROL の bit0 が1の時に画像データの読出しを行う。CTL_CONTROL の bit2 が1の場合は、PARAM_SIZE分転送すると停止する(bit0は自動クリア)。
そうでない場合は画像が来るたびに繰り返し転送を行う。
CTL_CONTROL の bit1 が1の時は転送開始や繰り返しのタイミングでパラメータが更新される。

PARAM_SIZE は PARAM_WIDTH×PARAM_HEIGHT のサイズである必要がある。

