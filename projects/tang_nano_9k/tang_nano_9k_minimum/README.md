# Tang Nano 9k のミニマム動作確認

## 概要
コマンドラインから [Tang Nano 9k](https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html) で
LEDチカチカをするだけの最小構成的なものです。

なるべくベタ書きで、見ればわかるようにしたつもりです。

## 環境

私は、Windows 版でライセンスを申請して、WSL2 から利用しています。

焼き込みには Windows版の [openFPGALoader](https://github.com/trabucayre/openFPGALoader) を利用させて頂いています。

WSLから Windows 版を利用しやすいようにパスの通ったところに下記のようなスクリプトを作っておいています。

パスは適用に自分の環境用に読み替えてください。

### gw_sh

```bash
#!/usr/bin/bash
/mnt/c/Gowin/Gowin_V1.9.9Beta-4/IDE/bin/gw_sh.exe $@
```

### openFPGALoader

```bash
#!/usr/bin/bash
/mnt/c/openFPGALoader/bin/openFPGALoader.exe $@
```

