# Parameter update controler with Video

## 概要

frame start を検出してパラメータ更新信号を出す


## レジスタ仕様

アドレスはWISHBONEのワードアドレス。
レジスタ幅や初期値は parameter 指定で変更可能。


| register name      |addr|R/W|size|description                   |
|:------------------ |:--:|:-:|:--:|:-----------------------------|
|CORE_ID             |0x00|RO|32| core ID     |
|CORE_VERSION        |0x01|RO|32| core verion |
|CONTROL             |0x04|RW| 2| bit[0]:更新予約<br>bit[1]:更新継続|
|INDEX               |0x05|RO|--| パラメータ受付毎にインクリメント|
|FRAME_COUNT         |0x06|RO|--| フレーム数カウント |


## 動作説明

各画像処理コアで処理途中にパラメータが変化すると不整合を起こすケースで次フレームを待ってパラメータ更新する機能があるものがあるが、コア内の整合性しか取れない。
本コアは、さらに画像処理コア間で不整合を起こさないために、後続コアに一斉に更新許可を出すのに用いる。

