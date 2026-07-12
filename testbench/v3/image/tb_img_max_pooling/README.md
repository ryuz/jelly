# jelly3_img_max_pooling テストベンチ

符号付き・符号なしデータの最大値プーリングをテストするシミュレーション環境です。

## 概要

- **DUT**：jelly3_img_max_pooling（3×3 デフォルト）
- **テストモード**：unsigned（0～255）/ signed（-128～127）
- **検証方法**：Python で期待値計算 → PPM 画像で diff 検証
- **シミュレータ**：Verilator / XSIM 対応

## ファイル構成

```
tb_img_max_pooling/
├── README.md                    # このファイル
├── gen_images.py               # テストパターン生成スクリプト
├── tb_top.sv                   # トップレベルモジュール（IS_SIGNED パラメータ付き）
├── tb_main.sv                  # テストベンチメインロジック
├── pattern/                    # 入力パターンディレクトリ
│   └── input_0000.ppm         # 入力画像（自動生成）
├── verilator/
│   ├── Makefile               # Verilator ビルド＆実行
│   ├── obj_dir/               # コンパイル出力
│   └── obj_dir_signed/        # signed モードの出力
└── xsim/
    ├── Makefile               # XSIM ビルド＆実行
    └── xsim.dir/              # コンパイル出力
```

## 使用例

### Verilator での実行

#### unsigned モード（デフォルト）
```bash
cd verilator
make all                    # ビルド・実行・diff
```

#### signed モード
```bash
cd verilator
make all-signed            # signed モードでビルド・実行・diff
```

#### 両方実行
```bash
cd verilator
make all-both              # unsigned と signed の両方を実行
```

#### 個別ステップ実行
```bash
make gen MODE=unsigned     # unsigned パターン生成
make build MODE=unsigned   # unsigned モード用バイナリ生成
make run MODE=unsigned     # シミュレーション実行
make diff MODE=unsigned    # 出力ファイル比較
make clean                 # クリーンアップ
```

### XSIM での実行

```bash
cd xsim
make all                   # unsigned モード
make all-signed            # signed モード
make all-both              # 両方実行
```

## テストパラメータ

Makefile 内で以下のパラメータをカスタマイズ可能：

```bash
WIDTH=16                   # 入力画像幅（デフォルト）
HEIGHT=12                  # 入力画像高さ（デフォルト）
POOL_N=3                   # 垂直プーリングカーネルサイズ
POOL_M=3                   # 水平プーリングカーネルサイズ
MODE=unsigned              # unsigned / signed
```

使用例：
```bash
make gen WIDTH=32 HEIGHT=24 POOL_N=2 POOL_M=2 MODE=signed
make build
make run
make diff
```

## 動作仕組み

### 1. テストパターン生成 `gen_images.py`

**unsigned モード**：
- 入力値：0～255 の疑似乱数
- 出力：各ピクセルの 3×3 領域内の最大値

**signed モード**：
- 入力値：-128～127 の疑似乱数（signed を意識した値）
- 出力：各ピクセルの 3×3 領域内の最大値（符号付き比較）

PPM 形式で保存される際、負の値は 2 の補数表現に変換されます：
- -1 → 255（0xFF）
- -128 → 128（0x80）

### 2. RTL 動作 `jelly3_img_max_pooling`

**IS_SIGNED パラメータ**：
- `IS_SIGNED=0`：unsigned として max 演算
- `IS_SIGNED=1`：signed として max 演算

内部で `jelly3_max_tree` の `IS_SIGNED` パラメータに渡され、比較器の振る舞いが変わります。

### 3. 検証 `diff`

Python 計算結果と RTL 出力を PPM 画像レベルで比較：
- 完全一致 → diff 合格 ✅
- 不一致 → diff 失敗 ❌（詳細表示）

## signed/unsigned テストの違い

| 項目 | unsigned | signed |
|------|----------|--------|
| 入力範囲 | 0～255 | -128～127 |
| 比較方式 | 大小比較（0～255） | 大小比較（-128～127） |
| 期待値計算 | Python int 比較 | Python int 比較（負対応） |
| PPM 表現 | そのまま | 2 の補数に変換 |

### 例：3×3 ウィンドウ内に [10, -20, 5] がある場合

| モード | 結果 |
|--------|------|
| **unsigned** | max(10, 236, 5) = 236 |
| **signed** | max(10, -20, 5) = 10 |

※ unsigned では -20 が 236（256-20）として解釈されます

## トラブルシューティング

### diff が失敗する場合

1. **タイムアウト**：シミュレーション時間が足りない
   - `tb_top.sv` の `#2000000` を増やす

2. **ビット幅ミスマッチ**：入出力のビット幅が異なる
   - `tb_main.sv` の `CH_BITS` を確認
   - `jelly3_img_max_pooling` の BYPASS_SIZE パラメータを確認

3. **座標計算エラー**：行/列の処理順序が間違っている
   - `gen_images.py` の `reflect101` 関数を確認
   - テストベンチの座標フロー（row_first/col_first）を確認

### シミュレーション実行に失敗する場合

```bash
# Verilator
make distclean           # 完全クリア
make all                 # 再ビルド

# XSIM
rm -rf xsim.dir .Xil
make all
```

## 実装詳細

### パラメータ指定機構（Makefile）

signed/unsigned モードの切り替えは、以下のフローで実現されます：

1. `gen_images.py --mode signed/unsigned` で テストパターン生成
2. `sed` で `tb_top.sv` の IS_SIGNED パラメータを動的に修正
3. 修正済みファイルを Verilator/XSIM にコンパイル
4. シミュレーション実行 → 出力ファイルリネーム

```makefile
# Verilator の場合
sed 's/parameter.*IS_SIGNED.*/parameter IS_SIGNED = 1'\''b1/' tb_top.sv > tmp_signed/tb_top_tmp.sv
verilator ... tmp_signed/tb_top_tmp.sv -Mdir obj_dir_signed
```

### 出力ファイル管理

- unsigned：`dut_0000.ppm` / `expected_0000.ppm`
- signed：`dut_0000_signed.ppm` / `expected_0000_signed.ppm`

## 参考資料

- jelly3_img_max_pooling RTL：[rtl/v3/image/jelly3_img_max_pooling.sv](../../rtl/v3/image/jelly3_img_max_pooling.sv)
- jelly3_max_tree RTL：[rtl/v3/math/jelly3_max_tree.sv](../../rtl/v3/math/jelly3_max_tree.sv)
- 関連テストベンチ：
  - [tb_img_ave_pooling](../tb_img_ave_pooling/)（平均値プーリング）
  - [tb_bin_or_pooling](../tb_bin_or_pooling/)（OR プーリング）

## 更新履歴

- **2026-05-27**：signed/unsigned 両モード対応、README 作成
