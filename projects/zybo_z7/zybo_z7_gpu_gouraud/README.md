# ZYBO-Z7 で RealTime-GPU (グーローシェーディング)

## 概要

ZYBO-Z7 でグーローシェーディングしたポリゴンをHDMIコネクタから表示するサンプルです。
なおコネクタはHDMIですが内部の電気的信号はDVIとなっております。
メモリレスで通常の画像フィルタの延長でポリゴン描画を実現しており、低遅延でリアルタイム性の高い画像生成が可能です。


## 環境

このような環境で実施しております。

- Digilent社 [Zybo Z7-20](https://reference.digilentinc.com/reference/programmable-logic/zybo-z7/start) (試してないですが多分 Z7-10でも大丈夫と思います)
- [Vivado 2019.2.1](https://japan.xilinx.com/support/download.html)
- [ikwzm氏](https://qiita.com/ikwzm) の [Debianブートイメージ](https://qiita.com/ikwzm/items/7e90f0ca2165dbb9a577)

基本的な環境構築は[こちらのブログ](https://qiita.com/Ryuz/items/fcda012ce0deeca068c6)でも紹介しておりますので参考にしてください。

ソフトウェアは Debian イメージ上でセルフコンパイル可能ですので、ホストPC側は Vivado のみでも開発が可能です(Vitisなどもある方がよいですが)。


## 動かし方

### gitリポジトリ取得

```
git clone https://github.com/ryuz/jelly.git
```

で一式取得してください。

### Vivadoで bit ファイルを作る

projects/zybo_z7/zybo_z7_gpu_gouraud/syn/vivado2019.2

に移動して Vivado から zybo_z7_gpu_gouraud.xpr を開いてください。

最初に BlockDesign を tcl から再構成する必要がります。

Vivado メニューの「Tools」→「Run Tcl Script」で、プロジェクトと同じディレクトリにある update_design.tcl を実行すると再構築を行うようにしています。

うまくいかない場合は、既に登録されている ps_core を手動で削除してから、ps_core.tcl を実行しても同じことができるはずです。


ps_core が生成されたら「Flow」→「Run Implementation」で合成を行います。正常に合成できれば

zybo_z7_gpu_gouraud.runs/impl_1

に zybo_z7_gpu_gouraud.bit が出来上がります。


### ZYBO Z7 で実行

ZYBO Z7 で Linux を起動してください。

次に projects/zybo_z7/zybo_z7_gpu_gouraud/app の内容一式と先ほど合成した zybo_z7_gpu_gouraud.bit を、ZYBO の Debian で作業できる適当なディレクトリにコピーします。bitファイルも同じappディレクトリに入れてください。

ZYBO 側では Debian が起動済みで ssh などで接続ができている前提ですので scp や samba などでコピーすると良いでしょう。app に関しては ZYBO から git で clone することも可能です。

この時、

- bootgen など必要なツールがインストールできていること
- sudo 権限のあるユーザーで実行すること

などの下準備がありますので、ブログなど参考に設定ください。

問題なければ、app をコピーしたディレクトリで

```
make all
```

と実行すれば zybo_z7_gpu_gouraud.out という実行ファイルが生成されます。

ここで

```
make run
```

とすると、Device Tree overlay によって、bit ファイルの書き込みなどを行った後にプログラムが起動し、HDMIに繋いだモニタに回転するキューブが表示されるはずです。
プログラムはしばらくすると自動で終了します。


なお、単独での Device Tree overlay のロード／アンロードは

```
make load
make unload
```

といったコマンドで実施可能です。


## 参考情報

- 作者ブログ記事
    - [低遅延リアルタイムGPUのFPGA実装](https://rtc-lab.com/2018/01/28/low-delay-realtime-gpu/)
    - [低遅延リアルタイムGPUでZテスト](https://rtc-lab.com/2018/02/04/low-delay-realtime-gpu-z-trest/)
    - [RealTime-GPU テクスチャマップ編](https://rtc-lab.com/2018/02/12/realtime-gpu-texture-map/)

- [Digital Visual InterfaceDVI](http://www.cs.unc.edu/Research/stc/FAQs/Video/dvi_spec-V1_0.pdf)

