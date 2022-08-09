#######################################
# テストベンチ用画像セットアップ
#######################################


TOOL_DIR=../../../tools


# windows7 wallpaper (https://windowswallpaper.miraheze.org/wiki/Windows_7)
Chrysanthemum.jpg:
	curl -o $@ https://static.miraheze.org/windowswallpaperwiki/f/f4/Chrysanthemum_%28Windows_7%29.jpg

Desert.jpg:
	curl -o $@ https://static.miraheze.org/windowswallpaperwiki/1/1d/Desert_%28Windows_7%29.jpg

Hydrangeas.jpg:
	curl -o $@ https://static.miraheze.org/windowswallpaperwiki/7/74/Hydrangeas_%28Windows_7%29.jpg

Jellyfish.jpg:
	curl -o $@ https://static.miraheze.org/windowswallpaperwiki/7/76/Jellyfish_%28Windows_7%29.jpg

Koala.jpg:
	curl -o $@ https://static.miraheze.org/windowswallpaperwiki/0/06/Koala.jpg

Lighthouse.jpg:
	curl -o $@ https://static.miraheze.org/windowswallpaperwiki/4/4f/Lighthouse.jpg

Penguins.jpg:
	curl -o $@ https://static.miraheze.org/windowswallpaperwiki/d/dc/Penguins_%28Windows_7%29.jpg

Tulips.jpg:
	curl -o $@ https://static.miraheze.org/windowswallpaperwiki/1/15/Tulips_%28Windows_7%29.jpg


# Convert
Chrysanthemum_640x480.ppm: Chrysanthemum.jpg
	$(TOOL_DIR)/img2ppm.py $< $@ --width 640 --height 480 --depth 8

Chrysanthemum_320x240.ppm: Chrysanthemum.jpg
	$(TOOL_DIR)/img2ppm.py $< $@ --width 320 --height 240 --depth 8

Chrysanthemum_640x480.pgm: Chrysanthemum.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 640 --height 480 --depth 8

Chrysanthemum_320x240.pgm: Chrysanthemum.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 320 --height 240 --depth 8

Chrysanthemum_640x480_bayer10.pgm: Chrysanthemum.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 640 --height 480 --depth 10 --bayer

Chrysanthemum_320x240_bayer10.pgm: Chrysanthemum.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 320 --height 240 --depth 10 --bayer

Chrysanthemum_640x480_bayer8.pgm: Chrysanthemum.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 640 --height 480 --depth 8  --bayer

Chrysanthemum_320x240_bayer8.pgm: Chrysanthemum.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 320 --height 240 --depth 8  --bayer


Penguins_640x480.ppm: Penguins.jpg
	$(TOOL_DIR)/img2ppm.py $< $@ --width 640 --height 480 --depth 8

Penguins_320x240.ppm: Penguins.jpg
	$(TOOL_DIR)/img2ppm.py $< $@ --width 320 --height 240 --depth 8

Penguins_640x480.pgm: Penguins.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 640 --height 480 --depth 8

Penguins_320x240.pgm: Penguins.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 320 --height 240 --depth 8

Penguins_640x480_bayer10.pgm: Penguins.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 640 --height 480 --depth 10 --bayer

Penguins_320x240_bayer10.pgm: Penguins.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 320 --height 240 --depth 10 --bayer

Penguins_640x480_bayer8.pgm: Penguins.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 640 --height 480 --depth 8  --bayer

Penguins_320x240_bayer8.pgm: Penguins.jpg
	$(TOOL_DIR)/img2pgm.py $< $@ --width 320 --height 240 --depth 8  --bayer



.PHONY : clean
clean:
	rm -f *.pgm *ppm

.PHONY : distclean
distclean: clean
	rm -f *.jpg
