#! /bin/bash


download_file () {
    if [ ! -e $1 ] ; then
        curl -o $1 $2
    fi
}

# 標準画像／サンプルデータ (http://www.ess.ic.kanagawa-it.ac.jp/app_images_j.html)
download_file color.zip http://www.ess.ic.kanagawa-it.ac.jp/std_img/colorimage/color.zip
download_file mono.zip  http://www.ess.ic.kanagawa-it.ac.jp/std_img/monoimage/mono.zip

# unzip
if [ ! -e color ] ; then
    unzip color.zip -d color
fi
if [ ! -e mono ] ; then
    unzip mono.zip
fi
