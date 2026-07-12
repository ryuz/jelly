# Image Ver3

## 概要

Ver3 は `jelly3_` 系の Image 実装群です。`mat_if` ベースの接続を中核に設計されています。

可能な範囲で OpenCV の命名に近づくようにしています。

画像としても行列としても扱いそうなデータは Mat を命名のベースとし、明らかに画像にしか施さない演算を行うものは Img を命名のベースとしています。


## jelly3_mat_if インターフェースの仕様

Ver3 では、画像データの受け渡しに `jelly3_mat_if.sv` でインターフェースを定義しています。

これは主に、`valid/ready` のハンドシェーク記述が苦手な方でも画像パイプラインを組みやすくするための設計です。`valid/ready` で厳密にストール制御する設計とは思想が異なるため、HLS との相性は良くありません。


### インターフェースのパラメータ

`jelly3_mat_if` は、用途に合わせてインタフェース幅や有効信号の扱いを変更できるようにパラメータ化されています。

特に Ver3 では `TAPS` により、1 サイクルで複数ピクセルを同時に処理する構成を取りやすくなっています。

| parameter |description |
|:--|:--|
|`USE_DE`| `de` 信号を使用するかを指定します。 |
|`USE_USER`| `user` 信号を使用するかを指定します。 |
|`USE_VALID`| `valid` 信号を使用するかを指定します。 |
|`TAPS`| 1 サイクルで同時に扱う画素タップ数です。`data[TAPS-1:0]` の形で並列処理できます。 |
|`DE_BITS`| `de` のビット幅です。既定値は `TAPS` です。用途に応じて 1bit 集約にもできます。 |
|`CH_DEPTH`| 1 画素あたりのチャネル数です。例: RGB なら 3 です。 |
|`CH_BITS`| 1 チャネルあたりのビット幅です。 |
|`ROWS_BITS`| 行数 (`rows`) を表現するビット幅です。 |
|`COLS_BITS`| 列数 (`cols`) を表現するビット幅です。 |
|`DATA_BITS`| データ総ビット幅です。通常 `CH_DEPTH * CH_BITS` です。 |
|`USER_BITS`| `user` 信号のビット幅です。 |

`TAPS` を増やすとスループットを上げやすくなりますが、周辺のバッファ構成や演算器リソースも合わせて設計する必要があります。

### jelly3_mat_if の信号仕様

`jelly3_mat_if` の主な信号は以下の通りです。

| signal name |description                                  |
|:----------- |:--------------------------------------------|
|reset        | リセット信号                                |
|clk          | クロック                                    |
|cke          | クロックイネーブル。処理可能なサイクルを示す |
|rows         | 画像の行数                                  |
|cols         | 画像の列数                                  |
|row_first    | 先頭行を示す                                |
|row_last     | 最終行を示す                                |
|col_first    | 行内先頭列を示す                            |
|col_last     | 行内最終列を示す                            |
|de           | 有効画素を示す。`DE_BITS` 幅のビット列       |
|data         | 画素データ。`TAPS` 本分を同時に扱える        |
|user         | ユーザー拡張信号                            |
|valid        | 信号有効を示す                              |

`jelly3_mat_if.sv` では `TAPS`、`CH_DEPTH`、`CH_BITS` などをパラメータ化しており、フィルタや並列処理の都合に合わせてデータ形状を合わせられます。


### jelly3_mat_if の cke の扱い

jelly3_mat_if のバスは有効ピクセルが無い場合や出力側が受けられない(バックプレッシャー)時に cke(クロックイネーブル)をネゲートするのが特徴です。

したがって、cke の有効な期間のみを処理すれば、データはすべて連続となり、パイプラインステージにおいてステージ前後のデータが左右のピクセルに必ず対応することを保証できます。

つまり

```verilog
always_ff @(posedge mat.clk) begin
    if ( mat.reset ) begin
        ...
    end
    else if ( mat.cke ) begin
        ...
    end
end
```

という形を保っている限りにおいて、データは常に連続してやってきているとみなしてハンドシェークを意識しないプログラミングが可能です。


### jelly3_mat_if の valid の扱い

`jelly3_mat_if` には多くの信号線があり、すべてにリセットを掛けるのは非効率です。

そこで、reset と cke 以外の信号については、valid が 1 の時のみ有効とするというルールの元、valid のみにリセットを掛ければ良いように設計しています。


### AXI4-Stream との対応

`jelly3_axi4s_to_mat.sv` と `jelly3_mat_to_axi4s.sv` により、AXI4-Stream との相互変換が可能です。

- `jelly3_axi4s_to_mat.sv`
	- `tuser[0]` をフレーム開始として解釈します。
	- `param_rows`/`param_cols` を基準に `row_first`/`row_last`/`col_first`/`col_last` を生成します。
	- 必要に応じて `param_blank` 行のブランキングを挿入します。
- `jelly3_mat_to_axi4s.sv`
	- `row_first && col_first` をフレーム開始として `tuser[0]` を立てます。
	- `col_last` を `tlast` に対応させます。
	- `tvalid` は `de && valid && cke` を使って生成します。


## 実装配置

- `rtl/v3/image`

## 主要モジュール

- `jelly3_mat_if.sv`
- `jelly3_axi4s_to_mat.sv`
- `jelly3_mat_to_axi4s.sv`
- `jelly3_img_demosaic_acpi.sv`
- `jelly3_img_color_matrix.sv`
- `jelly3_img_bayer_white_balance.sv`
- `jelly3_img_gamma_correction.sv`
- `jelly3_img_moment.sv`
- `jelly3_img_max_pooling.sv`


## 主要モジュール補足

- `jelly3_mat_if.sv`
	- Ver3 画像処理の基本インタフェースです。
- `jelly3_axi4s_to_mat.sv`
	- AXI4-Stream 入力を `mat_if` へ変換します。
- `jelly3_mat_to_axi4s.sv`
	- `mat_if` を AXI4-Stream 出力へ戻します。
- `jelly3_img_demosaic_acpi.sv`
	- Bayer 画像向け ACPI デモザイクを行います。
- `jelly3_img_color_matrix.sv`
	- 色変換行列による RGB 変換を行います。
- `jelly3_img_bayer_white_balance.sv`
	- Bayer 生データにホワイトバランス補正を適用します。
- `jelly3_img_gamma_correction.sv`
	- ガンマ補正を適用します。
- `jelly3_img_moment.sv`
	- 画像モーメント算出に利用できます。
- `jelly3_img_max_pooling.sv`
	- DNN 系前処理で使う MaxPooling を行います。

## 移行観点

- Ver2 のフラット信号接続から Ver3 `mat_if` 接続へ段階移行する構成を推奨します。
- 制御プレーンは `jelly3_` 系 library/dma と合わせると設計整合性が高まります。
