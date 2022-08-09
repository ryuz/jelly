#######################################
# テストベンチ用画像セットアップ
#######################################


TOOL_DIR=../../../tools


# 標準画像／サンプルデータ (http://www.ess.ic.kanagawa-it.ac.jp/app_images_j.html)
color.zip:
	curl -o $@ http://www.ess.ic.kanagawa-it.ac.jp/std_img/colorimage/color.zip

mono.zip:
	curl -o $@ http://www.ess.ic.kanagawa-it.ac.jp/std_img/monoimage/mono.zip

COLOR_FILES = color/Aerial.bmp \
              color/Airplane.bmp \
              color/Balloon.bmp \
              color/Earth.bmp \
              color/Girl.bmp \
              color/Mandrill.bmp \
              color/Parrots.bmp \
              color/Pepper.bmp \
              color/Sailboat.bmp \
              color/couple.bmp \
              color/milkdrop.bmp \
              # color/Lenna.bmp

MONO_FILES = mono/Airplane.bmp \
             mono/BARBARA.bmp \
             mono/BOAT.bmp \
             mono/BRIDGE.bmp \
             mono/Building.bmp \
             mono/Cameraman.bmp \
             mono/LAX.bmp \
             mono/LENNA.bmp \
             mono/Lighthouse.bmp \
             mono/Text.bmp \
             mono/WOMAN.bmp \
             mono/girl.bmp

$(COLOR_FILES): color.zip
	unzip -u -d color color.zip

$(MONO_FILES): mono.zip
	unzip -u mono.zip 


# convert
color/Mandrill_256x256.ppm: color/Mandrill.bmp
	${TOOL_DIR}/img2ppm.py $< $@ --width 256 --height 256

color/Mandrill_256x256.pgm: color/Mandrill.bmp
	${TOOL_DIR}/img2pgm.py $< $@ --width 256 --height 256

color/Mandrill_128x128.ppm: color/Mandrill.bmp
	${TOOL_DIR}/img2ppm.py $< $@ --width 128 --height 128

color/Mandrill_128x128.pgm: color/Mandrill.bmp
	${TOOL_DIR}/img2pgm.py $< $@ --width 128 --height 128

color/Mandrill_256x256_bayer10.pgm: color/Mandrill.bmp
	${TOOL_DIR}/img2pgm.py $< $@ --width 256 --height 256 --bayer --depth 10


mono/BOAT_256x256.pgm: mono/BOAT.bmp     
	${TOOL_DIR}/img2pgm.py $< $@ --width 256 --height 256

mono/BOAT_128x128.pgm: mono/BOAT.bmp     
	${TOOL_DIR}/img2pgm.py $< $@ --width 128 --height 128


# clean
.PHONY : clean
clean:
	rm -f color/*.ppm
	rm -f color/*.pgm
	rm -f mono/*.ppm
	rm -f mono/*.pgm

.PHONY : distclean
distclean: clean
	rm -fr color
	rm -fr mono
	rm -f *.zip

