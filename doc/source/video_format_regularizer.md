# Video format regularizer

## 概要

AXI4-Stream Video を指定フォーマットに正規化する


## レジスタ仕様

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


## 動作説明

主に画像入力デバイスの突然の切断やデータ欠け、フォーマット不一致などにより後段のDMAの転送データ数が合わずにデッドロックをおこすなどを防止する目的のものである。
