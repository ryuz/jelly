# Jelly -- SoC platform for FPGA

## 概要

MIPS互換のCPUコアを書き始めたのがきっかけですが、現状ではFPGAでSoCを実現する為のプラットフォームになりつつあります。
主に Xilinx のFPGAをターゲットにした、様々なコードを蓄積しており、主に Verilog 2001 で開発しております。

最近は、作者の発案したFPGA用のバイナリニューラルネットである LUT-Network の実行にも一部コードを流用しており、作者の中でも重要性が高まっております。

基本的には色々なものをごった煮で含んでいる状況ですが、参考になる部分だけ活用いただければと思います。

なお、現在少し詳細なドキュメントを[こちら](https://jelly-fpga.readthedocs.io/jv/master/)に準備中です。


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


## Zynqベースのシステム

- projects/zybo_z7_udmabuf_sample
    - [Zybo Z7 でudmabufを試すサンプル](projects/zybo_z7_udmabuf_sample/README.md)
- projects/zybo_z7_imx219
    - [Zybo Z7 で RaspberryPI Camera Module V2(Sony IMX219)](projects/zybo_z7_imx219/README.md)
- projects/zybo_z7_imx219_hdmi
    - [Zybo Z7 で カメラ画像(IMX219) をHDMIコネクタから表示](projects/zybo_z7_imx219_hdmi/README.md)
- projects/ultra96v2_udmabuf_sample
    - [Ultra96V2 でudmabufを試すサンプル](projects/ultra96v2_udmabuf_sample/README.md)
- projects/ultra96v2_display_port
    - [Ultra96V2 で DisplayPortを試すサンプル](projects/ultra96v2_display_port/README.md)
- projects/ultra96v2_imx219_display_port
    - [Ultra96V2 で カメラ画像(IMX219) をDisplayPortから表示](projects/ultra96v2_imx219_display_port/README.md)


## ライセンス

  license.txt にある通り、MIT ライセンスとして置いておきます。

