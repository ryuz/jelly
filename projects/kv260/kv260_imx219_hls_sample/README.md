
# HLSでカメラ画像を処理してみるサンプル

## 概要

HLSでカメラ画像にダイレクトに画像フィルタを適用してみるサンプルです。

ピクセルクロックでのコンスタントな処理を行うためには、ほとんどすべての場所で #pragma HLS pipeline 指定にて、Initiation Interval = 1 での処理を確保する必要があります。

コマンドラインにて make 一発で以下を一気に行う事が出来ます。

1. HLS で書かれたコードを合成
2. 合成した HLS を expoert
3. Vivado プロジェクトを生成して HLS を取り込み
4. Vivado 合成


## 合成方法

Vitis 2022.2 を想定しています。

コマンドラインにて 

```
source /tools/Xilinx/Vitis/2022.2/settings64.sh
```

を実行したのちに projects/kv260/kv260_imx219_hls_sample/syn/tcl に移動し、

```
make
```

とすれば完了です。


## HLSのシミュレーション

projects/kv260/kv260_imx219_hls_sample/hls の下にある gaussian_filter もしくは laplacian_filter に移動したのちに

```
make csim
```

で、C言語シミュレーション

```
make cosim
```

で、コシミュレーションが動きます。


## RTLのシミュレーション

### xsim でのシミュレーション

projects/kv260/kv260_imx219_hls_sample/sim/tb_top/xsim に移動したのちに

```
make
```

### verilator でのシミュレーション

projects/kv260/kv260_imx219_hls_sample/sim/tb_top/verilator に作成中ですが、HLS の出力に verilator 未対応出力があるようで対応できていません。


## 実機動作

実機に app ディレクトリと bit ファイルをコピーし、コピー先で

```
make
```

