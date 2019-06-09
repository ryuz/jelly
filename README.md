# Jelly -- SoC platform for FPGA

## 概要
FPGAでSoCを実現する為のプラットフォームです。
主に Xilinx のFPGAをターゲットにした、様々なコードを蓄積しており、主に Verlog で開発しております。

最近は、筆者の発案したFPGA用のバイナリニューラルネットである LUT-Network の実行にも一部コードを流用しており、重要性が高まっております。

基本的には色々なものをごった煮で含んでいる状況です。


## MIPS-I 互換プロセッサ

/rtl/cpu/
以下にあります。

Verilogの勉強を始めた頃に Spartan-3 向けに試しに書いてみたプロセッサです。

ブロック図などは[Webサイト](http://ryuz.my.coocan.jp/jelly/index.html)の方にあります。


## リアルタイムGPU

/rtl/gpu
以下にあります。

フレームメモリを使わないフィルタ型の低遅延なリアルタイム描画を目指したものです。

[動画](https://www.youtube.com/watch?v=vl-lhSOOlSk)はこちらです。


## ライブラリ群

もはやこれが Jelly のメインかもです

- rtl/library      FIFOとかRAMとか様々なRTLのパーツ
- rtl/bus          AXIとかWISHBONEとかのバスブリッジ等のパーツ
- rtl/math         GPUとかで使うような算術パーツ
- rtl/peripheral   UARTとかI2CとかTIMERとかののパーツ
- rtl/video        DVIとかHDMIとかのビデオ処理
- rtl/image        画像処理用パーツ(ニューラルネットの畳み込みでも利用)
- rtl/model        シミュレーション用の便利モデルいろいろ


## 命名の由来
 「CPU書いてみたんで名前付けたいんだけど何かいい案無い？」

 「プリン食べたい」

 「いや、あのそうじゃなくて....」

 「ゼリーでもいい」

 「はい...」

