# HLSで書いたIPをVivadoに取り込んで合成するサンプル

## 概要

コマンドラインにて make 一発で以下を一気に行うサンプルです。

単なる整数除算のみを行うシンプルなHLSコードで実験しています。


1. HLS で書かれたコードを合成
2. 合成した HLS を expoert
3. Vivado プロジェクトを生成して HLS を取り込み
4. Vivado 合成

## 合成方法

Vitis 2021.2 を想定しています。

コマンドラインにて 

```
source /tools/Xilinx/Vitis/2021.2/settings64.sh
```

を実行したのちに projects/ultra96v2_hls_test/syn/tcl に移動し、

```
make
```

とすれば完了です。


## HLSのシミュレーション

projects/ultra96v2_hls_test/hls に移動したのちに

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

projects/ultra96v2_hls_test/sim/tb_top/xsim に移動したのちに

```
make
```

### verilator でのシミュレーション

projects/ultra96v2_hls_test/sim/tb_top/verilator に移動したのちに

```
make
```

## 実機動作

実機に app ディレクトリと bit ファイルをコピーし、コピー先で

```
make
```


## 参考にさせて頂いた情報

こちらをかなり参考にさせて頂きました。
素晴らしい情報を公開いただいて感謝申し上げます。

- https://qiita.com/ikwzm/items/a0120079d2f7f86a5904
- https://kenta11.github.io/2019/02/12/make-for-Vivado-HLS/


