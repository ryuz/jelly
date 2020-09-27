# jelly_dma_stream_read module

## 概要

(まだデバッグ中、writeもセットで開発中)

AXI4 メモリバスからN次元読み出して Stream を出力する。
読出し先のバッファ制御と、読出しデータの利用側とを独立性高く扱いつつ、メモリアクセス効率を保つことを目的に設計を行っている。

内部にFIFOバッファを有しており、バッファ溢れしない分量のみを読み出し管理する為、利用側はデータ利用に先立って起動しておけば、後は読み出し制御とは独立してデータを取り出して利用するのみでよい。

CPUからのレジスタ状態変化や割り込みは、内部FIFOの残量に無関係にAXI4バスへのメモリアクセスが完了した段階で発生するため、データ読出し側とは独立して、読み出しバッファの解放と、次の読出しバッファのアロケートを効率的に先行実施可能である。
(データの完了を知りたい場合は、データを利用する側のコアから完了割り込みを受けるべきである)。


## レジスタ仕様

アドレスはWISHBONEのワードアドレス。
レジスタ幅や初期値は parameter 指定で変更可能。

| register name |addr|R/W|size|description                   |
|:------------- |:--:|:-:|:--:|:-----------------------------|
|CORE_ID        |0x00|RO | 32 | core ID     |
|CORE_VERSION   |0x01|RO | 32 | core verion |
|CORE_CONFIG    |0x03|RO | 32 | サポート次元数(Nの値) |
|CTL_CONTROL    |0x04|RW |  4 | bit[0]:有効化<br>bit[1]:パラメータ更新予約(自動クリア)<br>bit[2]:ワンショット転送<br>bit[3] 自動アドレス取得有効 |
|CTL_STATUS     |0x05|RO |  1 | 動作中に1となる |
|CTL_INDEX      |0x07|RO |INDEX_WIDTH| 新規パラメータ反映毎にインクリメント
|IRQ_ENABLE     |0x08|RW |  1 | 1でIQR有効 |
|IRQ_STATUS     |0x09|RO |  1 | 現在のIQR保留状態 |
|IRQ_CLR        |0x0a|WO |  1 | 1を書き込むと保留IRQクリア |
|IRQ_SET        |0x0b|WO |  1 | 1を書き込むと保留IRQセット |
|PARAM_ARADDR   |0x10|RW |AXI4_ADDR_WIDTH| 転送アドレス(非自動割り当て時)
|PARAM_ARLEN_MAX|0x11|RW |AXI4_LEN_WIDTH| AXI4バスでの1回の最大転送サイズから1を引いたもの)
|PARAM_ARLEN0   |0x20|RW |ARLEN0_WIDTH |0次元目の転送量からARLEN＿OFFSETを引いた値|
|PARAM_ARLEN1   |0x24|RW |ARLEN1_WIDTH |1次元目の転送長らARLEN＿OFFSETを引いた値|
|PARAM_ARSTEP1  |0x25|RW |ARSTEP1_WIDTH|1次元目の転送ステップ(バイト単位)|
|PARAM_ARLEN2   |0x28|RW |ARLEN2_WIDTH |2次元目の転送長らARLEN＿OFFSETを引いた値|
|PARAM_ARSTEP2  |0x29|RW |ARSTEP2_WIDTH|2次元目の転送ステップ(バイト単位)|
|PARAM_ARLEN3   |0x2c|RW |ARLEN3_WIDTH |3次元目の転送長らARLEN＿OFFSETを引いた値|
|PARAM_ARSTEP3  |0x2d|RW |ARSTEP3_WIDTH|3次元目の転送ステップ(バイト単位)|
|PARAM_ARLEN4   |0x30|RW |ARLEN4_WIDTH |4次元目の転送長らARLEN＿OFFSETを引いた値|
|PARAM_ARSTEP4  |0x31|RW |ARSTEP4_WIDTH|4次元目の転送ステップ(バイト単位)|
|PARAM_ARLEN5   |0x34|RW |ARLEN5_WIDTH |5次元目の転送長らARLEN＿OFFSETを引いた値|
|PARAM_ARSTEP5  |0x35|RW |ARSTEP5_WIDTH|5次元目の転送ステップ(バイト単位)|
|PARAM_ARLEN6   |0x38|RW |ARLEN6_WIDTH |6次元目の転送長らARLEN＿OFFSETを引いた値|
|PARAM_ARSTEP6  |0x39|RW |ARSTEP6_WIDTH|6次元目の転送ステップ(バイト単位)|
|PARAM_ARLEN7   |0x3c|RW |ARLEN7_WIDTH |7次元目の転送長らARLEN＿OFFSETを引いた値|
|PARAM_ARSTEP7  |0x3d|RW |ARSTEP7_WIDTH|7次元目の転送ステップ(バイト単位)|
|PARAM_ARLEN8   |0x30|RW |ARLEN8_WIDTH |8次元目の転送長らARLEN＿OFFSETを引いた値|
|PARAM_ARSTEP8  |0x31|RW |ARSTEP8_WIDTH|8次元目の転送ステップ(バイト単位)|
|PARAM_ARLEN9   |0x44|RW |ARLEN9_WIDTH |9次元目の転送長らARLEN＿OFFSETを引いた値|
|PARAM_ARSTEP9  |0x45|RW |ARSTEP9_WIDTH|9次元目の転送ステップ(バイト単位)|


## 動作説明

CTL_CONTROL の bit0 が1の時にN次元構造のデータの読出しを行い、各次元の先頭末尾で対応するbit位置のフラグを立てたデータを出力することが可能である。

CTL_CONTROL の bit2 に1を立てない限りは、繰り返し同じ動作を行う。CTL_CONTROL の bit2 に1を立てた場合は次回転送完了で、bit0は自動クリアされて停止する。

CTL_CONTROL の bit1 を立てると 1の時は繰り返しのタイミングでパラメータのみ動的に更新することが可能である。パラメータ更新と同時に CTL_CONTROL の bit1 は自動クリアされる。
内部的にシャドーレジスタを有しており、そちらにコピーされる為、動作中もパラメータレジスタは書き換えてかまわない。

割り込みは、1回の転送が終わる毎に発生する。パラメータの更新予約をしていた場合は、ここで更新が行われるため、さらに新しいバッファの割り当てなどをこのタイミングで行うことが可能である。


## parameter 設定

デフォルト値から変更する必要のある可能性のあるものだけ記載する。

| parameter name     |description                   |
|:------------------ |:-----------------------------|
|N                   | 次元数 (1～10) | 
|WB_ASYNC            | WISHBONEバスとAXIバスが非同期か| 
|RASYNC              | ReadDataのストリームバスとAXIバスが非同期か| 
|BYTE_WIDTH          | 1バイトのbit数| 
|BYPASS_GATE         | 出力の整形ゲートをバイパス(アライメント無し/フラグ無し)| 
|BYPASS_ALIGN        | AXI4の4kアライメント処理をバイパス| 
|ALLOW_UNALIGNED     | バスサイズのアライメントに合わないアクセスを許す| 
|HAS_RFIRST          | s_rfirst信号を備える | 
|HAS_RLAST           | s_rlast信号を備える | 
|AXI4_ID_WIDTH       | AXI4のID幅 | 
|AXI4_ADDR_WIDTH     | AXI4のADDR幅 | 
|AXI4_DATA_SIZE      | AXI4のデータサイズをlog2で指定(0:8bit, 1:16bit, 2:32bit, ...) | 
|AXI4_LEN_WIDTH      | AXI4の arlen の幅 | 
|AXI4_QOS_WIDTH      | AXI4の arqos の幅 | 
|AXI4_ARID           | AXI4の arid の値(固定値) | 
|AXI4_ARLOCK         | AXI4の arlock の値(固定値) | 
|AXI4_ARCACHE        | AXI4の arcach の値(固定値) | 
|AXI4_ARPROT         | AXI4の arprot の値(固定値) | 
|AXI4_ARQOS          | AXI4の arqos の値(固定値) | 
|AXI4_ARREGION       | AXI4の arregion の値(固定値) | 
|S_RDATA_WIDTH       | 読み出したストリームのデータ幅 | 
|CAPACITY_WIDTH      | 内部でキューイングする転送量のbit幅(一度にDAMに予約する転送サイズがAXI4バス側の転送量に換算して総和が保持できるbit幅) | 
|ARLEN_OFFSET        | 転送サイズのオフセット(1を指定すると転送サイズから1引いた値を設定) | 
|WB_ADR_WIDTH        | WISHBONEバスのアドレス幅(8以上) |
|WB_DAT_WIDTH        | WISHBONEバスのデータ幅 |
|WB_SEL_WIDTH        | WISHBONEバスのバイト選択の幅 |
|INDEX_WIDTH         | INDEXレジスタの幅 |
|ARLEN0_WIDTH        | 0次元目の転送量指定幅 | 
|ARLEN1_WIDTH        | 1次元目の転送量指定幅(N >=2 の時のみ) | 
|ARLEN2_WIDTH        | 2次元目の転送量指定幅(N >=3 の時のみ) | 
|ARLEN3_WIDTH        | 3次元目の転送量指定幅(N >=4 の時のみ) | 
|ARLEN4_WIDTH        | 4次元目の転送量指定幅(N >=5 の時のみ) | 
|ARLEN5_WIDTH        | 5次元目の転送量指定幅(N >=6 の時のみ)| 
|ARLEN6_WIDTH        | 6次元目の転送量指定幅(N >=7 の時のみ)| 
|ARLEN7_WIDTH        | 7次元目の転送量指定幅(N >=8 の時のみ)| 
|ARLEN8_WIDTH        | 8次元目の転送量指定幅(N >=9 の時のみ)| 
|ARLEN9_WIDTH        | 9次元目の転送量指定幅(N >=10 の時のみ)| 
|ARSTEP1_WIDTH       | 1次元目の転送ステップ量指定幅(N >=2 の時のみ)| 
|ARSTEP2_WIDTH       | 2次元目の転送ステップ量指定幅(N >=3 の時のみ)| 
|ARSTEP3_WIDTH       | 3次元目の転送ステップ量指定幅(N >=4 の時のみ)| 
|ARSTEP4_WIDTH       | 4次元目の転送ステップ量指定幅(N >=5 の時のみ)| 
|ARSTEP5_WIDTH       | 5次元目の転送ステップ量指定幅(N >=6 の時のみ)| 
|ARSTEP6_WIDTH       | 6次元目の転送ステップ量指定幅(N >=7 の時のみ)| 
|ARSTEP7_WIDTH       | 7次元目の転送ステップ量指定幅(N >=8 の時のみ)| 
|ARSTEP8_WIDTH       | 8次元目の転送ステップ量指定幅(N >=9 の時のみ)| 
|ARSTEP9_WIDTH       | 9次元目の転送ステップ量指定幅(N >=10 の時のみ)| 
|RFIFO_PTR_WIDTH     | rチャネルのFIFOバッファのポインタ幅(サイズのlog2となる) FIFOサイズ以上の転送は出来ないので注意|
|RFIFO_RAM_TYPE      | rチャネルのFIFOバッファのタイプ。"block" で BRAM, "distributed" で分散RAMを利用する |


## ポート仕様

本モジュールのポートの各信号は以下の通り。

| port name     |I/O |size             |description                   |
|:------------- |:--:|:---------------:|:-----------------------------|
|endian          | I | 1               | エンディアン(0:little, 1:big) |
|s_wb_rst_i      | I | 1               | WISHBONEバス リセット |
|s_wb_clk_i      | I | 1               | WISHBONEバス クロック |
|s_wb_adr_i      | I | WB_ADR_WIDTH    | WISHBONEバス アドレス |
|s_wb_dat_i      | I | WB_DAT_WIDTH    | WISHBONEバス 書き込みデータ |
|s_wb_dat_o      | O | WB_DAT_WIDTH    | WISHBONEバス 読み出しデータ |
|s_wb_we_i       | I | 1               | WISHBONEバス 読み書き選択 |
|s_wb_sel_i      | I | WB_SEL_WIDTH    | WISHBONEバス バイトセレクト |
|s_wb_stb_i      | I | 1               | WISHBONEバス ストローブ |
|s_wb_ack_o      | O | 1               | WISHBONEバス アクノリッジ |
|out_irq         | O | 1               | IRQ信号(レベル割り込み) |
|buffer_request  | O | 1               | バッファ割り当て要求 |
|buffer_release  | O | 1               | バッファ解放 |
|buffer_addr     | I | AXI4_ADDR_WIDTH | バッファアドレス |
|s_rresetn       | I |                 | Read Stream バス リセット |
|s_rclk          | I |                 | Read Stream バス クロック |
|s_rdata         | O | S_RDATA_WIDTH   | Read Stream バス データ |
|s_rfirst        | O | N               | Read Stream バス 各次元の先頭フラグ |
|s_rlast         | O | N               | Read Stream バス 各次元の末尾フラグ |
|s_rvalid        | O |                 | Read Stream バス valid信号 |
|s_rready        | I |                 | Read Stream バス ready信号 |
|m_aresetn       | I |                 | AXI4 バス リセット(負論理) |
|m_aclk          | I |                 | AXI4 バス クロック |
|m_axi4_arid     | O | AXI4_ID_WIDTH   | AXI4 バス arid 信号 |
|m_axi4_araddr   | O | AXI4_ADDR_WIDTH | AXI4 バス araddr 信号 |
|m_axi4_arlen    | O | AXI4_LEN_WIDTH  | AXI4 バス arlen 信号 |
|m_axi4_arsize   | O | 3               | AXI4 バス arsize 信号 |
|m_axi4_arburst  | O | 2               | AXI4 バス arburst 信号 |
|m_axi4_arlock   | O | 1               | AXI4 バス arlock 信号 |
|m_axi4_arcache  | O | 4               | AXI4 バス arcache 信号 |
|m_axi4_arprot   | O | 2               | AXI4 バス arprot 信号 |
|m_axi4_arqos    | O | AXI4_QOS_WIDTH  | AXI4 バス arqos 信号 |
|m_axi4_arregion | O | 4               | AXI4 バス arregion 信号 |
|m_axi4_arvalid  | O | 1               | AXI4 バス arvalid 信号 |
|m_axi4_arready  | I | 1               | AXI4 バス arready 信号 |
|m_axi4_rid      | I | AXI4_ID_WIDTH   | AXI4 バス rid 信号 |
|m_axi4_rdata    | I | AXI4_DATA_WIDTH | AXI4 バス rdata 信号 |
|m_axi4_rresp    | I | 2               | AXI4 バス rresp 信号 |
|m_axi4_rlast    | I |                 | AXI4 バス rlast 信号 |
|m_axi4_rvalid   | I |                 | AXI4 バス rvalid 信号 |
|m_axi4_rready   | O |                 | AXI4 バス rready 信号 |


endian は 動的に変更することは想定していないので注意。バス幅変換が作用した場合に動作が変わる。
