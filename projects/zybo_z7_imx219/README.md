# ZYBO-Z7 で Raspberry Pi Camera Module V2 (Sony IMX219) を 1000fpsで使うサンプル

## 概要
タイトルのとおり、ZYBO-Z7 で Raspberry Pi Camera Module V2 (Sony IMX219) を 1000fpsで使うサンプルです。
もちろん 3280×2464@20fps もちゃんとできますのでご安心を。


## 環境

このような環境で実施しております。

- Digilent社 [Zybo Z7-20](https://reference.digilentinc.com/reference/programmable-logic/zybo-z7/start) (試してないですが多分 Z7-10でも大丈夫と思います)
- Raspberry Pi Camera Module V2
- [Vivado 2019.2.1](https://japan.xilinx.com/support/download.html)
- [ikwzm氏](https://qiita.com/ikwzm) の [Debianブートイメージ](https://qiita.com/ikwzm/items/7e90f0ca2165dbb9a577)
- Debianイメージへの OpenCV など各種開発環境のインストール
- X-Window server となるPC (作者は Windows10 + [Xming](https://sourceforge.net/projects/xming/) で実施)

基本的な環境構築は[こちらのブログ](https://ryuz.qrunch.io/entries/jU8BkKu8bxqOeGAC)でも紹介しておりますので参考にしてください。

ソフトウェアは Debian イメージ上でセルフコンパイル可能ですので、ホストPC側は Vivado のみでも開発が可能です(Vitisなどもある方がよいですが)。


## 動かし方

### gitリポジトリ取得

```
git clone https://github.com/ryuz/jelly.git
```

で一式取得してください。

Vivado から

projects/zybo_z7_imx219/syn/vivado2019.2/zybo_z7_imx219.xpr

を開いてください。

続けて、プロジェクトと同じディレクトリにある 


### Vivadoで bit ファイルを作る



https://github.com/lvsoft/Sony-IMX219-Raspberry-Pi-V2-CMOS
