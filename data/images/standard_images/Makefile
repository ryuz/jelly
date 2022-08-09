#######################################
# テストベンチ用画像セットアップ
#######################################


TOOL_DIR=../../../tools


# 標準画像／サンプルデータ (http://www.ess.ic.kanagawa-it.ac.jp/app_images_j.html)
color.zip:
	curl -o $@ http://www.ess.ic.kanagawa-it.ac.jp/std_img/colorimage/color.zip

mono.zip:
	curl -o $@ http://www.ess.ic.kanagawa-it.ac.jp/std_img/monoimage/mono.zip


.PHONY : color
color: color.zip
	unzip color.zip -d color

.PHONY : mono
mono: mono.zip
	unzip mono.zip

color/Mandrill.bmp: color
color/Aerial.bmp: color
color/Airplane.bmp: color
color/Balloon.bmp: color
color/Earth.bmp: color
color/Girl.bmp: color
# color/Lenna.bmp: color
color/Mandrill.bmp: color
color/Parrots.bmp: color
color/Pepper.bmp: color
color/Sailboat.bmp: color
color/couple.bmp: color
color/milkdrop.bmp: color

mono/Airplane.bmp: mono
mono/BARBARA.bmp: mono
mono/BOAT.bmp: mono
mono/BRIDGE.bmp: mono
mono/Building.bmp: mono
mono/Cameraman.bmp: mono
mono/LAX.bmp: mono
mono/LENNA.bmp: mono
mono/Lighthouse.bmp: mono
mono/Text.bmp: mono
mono/WOMAN.bmp: mono
mono/girl.bmp: mono


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

