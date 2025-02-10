# Jelly -- SoC platform for FPGA

## 概要

もともとMIPS互換のCPUコアを書き始めたのがきっかけですが、現状ではFPGAでSoCを実現する為のプラットフォームになりつつあります。
主に Xilinx のFPGAをターゲットにした、様々なコードを蓄積しており、主に Verilog 2001 と SystemVerilog で開発しております。

最近は、作者の発案したFPGA用のバイナリニューラルネットである [LUT-Network](https://github.com/ryuz/BinaryBrain) の実行にも一部コードを流用しており、作者の中でも重要性が高まっております。

基本的には色々なものをごった煮で含んでいる状況ですが、参考になる部分だけ活用いただければと思います。

なお、現在少し詳細なドキュメントを[こちら](https://jelly-fpga.readthedocs.io/jv/master/)に準備中です。

作者が書き溜めたソースの集合体で、多数のプロジェクトを内包したモノリポとなっております。


## いろいろなサンプルプロジェクト

Jelly 内のサンプルプログラムの紹介です。


### ZynqMP 共通

- projects/zynqmp/zynqmp_rpu/zynqmp_rpu_rust
    - [ZynqMP の rpu を C++ と Rust で試すサンプル](projects/zynqmp/zynqmp_rpu/README.md)

### Kria KV260

- projects/kv260/kv260_imx219
    - [Kria KV260 で カメラ画像(IMX219) を動かすサンプル](projects/kv260/kv260_imx219/README.md)
- projects/kv260/kv260_rtos_sample  
    - [Kria KV260 で FPGA化した リアルタイムOS を試すサンプル](projects/kv260/kv260_rtos/README.md)
- projects/kv260/kv260_jfive_simple_controller
    - [Kria KV260 で 自作RISC-V(4段パイプライン)を200MHzで試すサンプル](projects/kv260/kv260_jfive_simple_controller/README.md)
- projects/kv260/kv260_jfive_micro_controller
    - [Kria KV260 で 自作RISC-V(6段パイプライン)を250MHzで試すサンプル](projects/kv260/kv260_jfive_micro_controller/README.md)

- projects/kv260/kv260_rtos
    - [Kria KV260 で FPGA化した リアルタイムOS を試すサンプル](projects/kv260/kv260_rtos/README.md)
    - Interface 2023年10月号付録 [FPGAマガジン No.1](https://fpga.tokyo/real-time-os-on-fpga/)で記事にしております

- projects/kv260/kv260_imx219_mnist_seg
    - [Kria KV260 で Raspberry V2 カメラ の 1000fps で MNIST のセメンティックセグメンテーションを行う](projects/kv260/kv260_imx219_mnist_seg/README.md)
    - Interface 2024年10月号付録 [FPGAマガジン No.3](https://fpga.tokyo/no3-2/)で記事にしております

- projects/kv260/kv260_blinking_led
    - [Kria KV260 で PL単独で LED チカチカ を試すサンプル](projects/kv260/kv260_blinking_led/README.md)
- projects/kv260/kv260_blinking_led_ps
    - [Kria KV260 で PSから PL経由で LED チカチカ を試すサンプル](projects/kv260/kv260_sample/README.md)
- projects/kv260/kv260_udmabuf_sample
    - [Kria KV260 で udmabuf を試すサンプル](projects/kv260/kv260_udmabuf_sample/README.md)
- projects/kv260/kv260_devdrv_sample
    - [Kria KV260 で 自作デバイスドライバを試すサンプル](projects/kv260/kv260_devdrv_sample/README.md)


### Kria KR260

- projects/kr260/kr260_blinking_led
    - [Kria KR260 で LED チカチカ を試すサンプル](projects/kr260/kr260_blinking_led/README.md)
- projects/kr260/kr260_udmabuf_sample
    - [Kria KR260 で udmabuf を試すサンプル](projects/kr260/kr260_udmabuf_sample/README.md)
- projects/kr260/kr260_devdrv_sample
    - [Kria KR260 で 自作デバイスドライバを試すサンプル](projects/kr260/kr260_devdrv_sample/README.md)


### Ultra96 V2

- projects/ultra96v2/ultra96v2_udmabuf_sample
    - [Ultra96V2 でudmabufを試すサンプル](projects/ultra96v2/ultra96v2_udmabuf_sample/README.md)
- projects/ultra96v2/ultra96v2_display_port
    - [Ultra96V2 で DisplayPortを試すサンプル](projects/ultra96v2/ultra96v2_display_port/README.md)
- projects/ultra96v2/ultra96v2_imx219_display_port
    - [Ultra96V2 で カメラ画像(IMX219) をDisplayPortから表示](projects/ultra96v2/ultra96v2_imx219_display_port/README.md)
- projects/ultra96v2/ultra96v2_rtos
    - [Ultra96V2 で FPGA化した リアルタイムOS を試すサンプル](projects/ultra96v2/ultra96v2_rtos/README.md)
- projects/ultra96v2/ultra96v2_jfive_sample
    - [Ultra96V2 で 自作RISC-V(4段パイプライン)を試すサンプル](projects/ultra96v2/ultra96v2_jfive_sample/README.md)
- projects/ultra96v2/ultra96v2_hls_test
    - [Ultra96V2 で コマンドラインだけでHLSで書いたIPをVivadoに取り込んで合成するサンプル](projects/ultra96v2/ultra96v2_hls_sample/README.md)
- projects/ultra96v2/ultra96v2_imx219_hls_sample
    - [Ultra96V2 で HLSでカメラ画像を処理してみるサンプル](projects/ultra96v2/ultra96v2_imx219_hls_sample/README.md)

### Zybo Z7

- projects/zybo_z7/zybo_z7_udmabuf_sample
    - [Zybo Z7 でudmabufを試すサンプル](projects/zybo_z7/zybo_z7_udmabuf_sample/README.md)
- projects/zybo_z7/zybo_z7_imx219
    - [Zybo Z7 で RaspberryPI Camera Module V2(Sony IMX219)](projects/zybo_z7/zybo_z7_imx219/README.md)
- projects/zybo_z7/zybo_z7_imx219_hdmi
    - [Zybo Z7 で カメラ画像(IMX219) をHDMIコネクタから表示](projects/zybo_z7/zybo_z7_imx219_hdmi/README.md)

### Tang Nano 4k

- projects/tang_nano_4k/tang_nano_4k_blinking_led
    - [Tang Nano 4k の LEDチカチカ](projects/tang_nano_4k/tang_nano_4k_blinking_led/README.md)

- projects/tang_nano_4k/tang_nano_4k_mnist
    - [Tang Nano 4k の MNIST 認識 (LUT-Network)](projects/tang_nano_4k/tang_nano_4k_mnist/README.md)
    - Interface 2024年12月号付録 [GOWING Vol.4](https://fpga.tokyo/gowin_vol4_news/)で記事にしております

### Tang Nano 9k

- projects/tang_nano_9k/tang_nano_9k_blinking_led
    - [Tang Nano 9k の LEDチカチカ](projects/tang_nano_9k/tang_nano_9k_blinking_led/README.md)

- projects/tang_nano_9k/tang_nano_9k_blinking_led
    - [Tang Nano 9k の HDMI(DVI)出力確認](projects/tang_nano_9k/tang_nano_9k_hdmi_sample/README.md)



## ライブラリ群

各プロジェクトで利用している Jelly の共有ライブラリ群が rtl の下にあります。いくつかのバージョンで整理を始めており

- v1  Verilog-2001 で記述した昔のコード
- v2  一部 SystemVerilog の機能を限定的に利用し始めたコード
- v3  SystemVerilog の Interface や type などの機能をフルに使い始めたもの
- jellyvl  実験的に [Veryl](https://github.com/veryl-lang/veryl) を試したもの(submodule)

となっています。 v2 までは logic や always_ff を使い始めた程度なので SystemVerilog 対応を謡っているものなら概ね対応可能と思われます。

v3 は処理系を選ぶ可能性があります。

rtl の下にある分類を v2 を例に説明すると

- rtl/v2/library      FIFOとかRAMとか様々なRTLのパーツ
- rtl/v2/bus          AXIとかWISHBONEとかのバスブリッジ等のパーツ
- rtl/v2/math         GPUとかで使うような算術パーツ
- rtl/v2/peripheral   UARTとかI2CとかTIMERとかののパーツ
- rtl/v2/video        DVIとかHDMIとかのビデオ処理
- rtl/v2/image        画像処理用パーツ(ニューラルネットの畳み込みでも利用)
- rtl/v2/model        シミュレーション用の便利モデルいろいろ

のような感じになっています。


## 各種機能開発

### MIPS-I 互換プロセッサ

作者が一番最初に Verilog の勉強を始めるきっかけとして 自作CPU に挑戦したものです。

/rtl/v1/mipsi/

以下にあります。

Verilogの勉強を始めた頃に Spartan-3 向けに試しに書いてみたプロセッサです。

ブロック図などは[Webサイト](http://ryuz.my.coocan.jp/legacy/jelly/index.html)の方にあります。


### RISV-V 互換プロセッサ

/rtl/jfive

以下にあります。

サンプルは

- [Ultra96V2 で 自作RISC-V(4段パイプライン)を試すサンプル](projects/ultra96v2/ultra96v2_jfive_sample/README.md)
- [Kria KV260 で 自作RISC-V(4段パイプライン)を試すサンプル](projects/kv260/kv260_jfive_simple_controller/README.md)
- [Kria KV260 で 自作RISC-V(6段パイプライン)を試すサンプル](projects/kv260/kv260_jfive_micro_controller/README.md)
- [Kria KV260 で RISC-V 風のバレルプロセッサ](https://github.com/ryuz/jelly/tree/master/projects/kv260/kv260_jfive_v3_sample)

などになります。

### FPGA化リアルタイムOS

/rtl/rtos

以下にあります。

FPGAで作成したRealTime-OSアクセラレータです。

今のところ ZynqMP の RPU(Cortex-R5) のアクセラレートのみですが、ITRON風味のRTOSスケジューリング補助回路となっています。

現状 Rust での開発を想定して[サンプル](projects/ultra96v2/ultra96v2_rtos/README.md)を準備しております。


### リアルタイムGPU

/rtl/v1/gpu

以下にあります。

フレームメモリを使わないフィルタ型の低遅延なリアルタイム描画を目指したものです。

[動画](https://www.youtube.com/watch?v=vl-lhSOOlSk)はこちらです。



## その他

ZynqMP ネタが増えてきたので[ZynqMPを理解しよう](https://zenn.dev/ryuz88/books/zynqmp_study)という記事を書いてみました。


## 作者情報

渕上 竜司(Ryuji Fuchikami)

- e-mail : ryuji.fuchikami@nifty.com
- github : https://github.com/ryuz
- web-site : https://ryuz88.sakura.ne.jp
- zenn : https://zenn.dev/ryuz88
- tech-blog : https://ryuz.hatenablog.com/
- blog : http://ryuz.txt-nifty.com
- X(twitter) : https://x.com/ryuz88
- facebook : https://www.facebook.com/ryuji.fuchikami
- SpeakerDeck : https://speakerdeck.com/ryuz88
- YouTube : https://www.youtube.com/user/nekoneko1024


## ライセンス

  license.txt にある通り、MIT ライセンスとして置いておきます。

  ただし submodule など、他から引用しているものについてはその限りではありませんので、個別ライセンス記述がある場合はそちらに従ってください。

