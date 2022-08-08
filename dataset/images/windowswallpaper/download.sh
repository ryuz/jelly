#! /bin/bash


download_file () {
    if [ ! -e $1 ] ; then
        curl -o $1 $2
    fi
}

# windows7 wallpaper (https://windowswallpaper.miraheze.org/wiki/Windows_7)
download_file Chrysanthemum.jpg https://static.miraheze.org/windowswallpaperwiki/f/f4/Chrysanthemum_%28Windows_7%29.jpg
download_file Desert.jpg        https://static.miraheze.org/windowswallpaperwiki/1/1d/Desert_%28Windows_7%29.jpg
download_file Hydrangeas.jpg    https://static.miraheze.org/windowswallpaperwiki/7/74/Hydrangeas_%28Windows_7%29.jpg
download_file Jellyfish.jpg     https://static.miraheze.org/windowswallpaperwiki/7/76/Jellyfish_%28Windows_7%29.jpg
download_file Koala.jpg         https://static.miraheze.org/windowswallpaperwiki/0/06/Koala.jpg
download_file Lighthouse.jpg    https://static.miraheze.org/windowswallpaperwiki/4/4f/Lighthouse.jpg
download_file Penguins.jpg      https://static.miraheze.org/windowswallpaperwiki/d/dc/Penguins_%28Windows_7%29.jpg
download_file Tulips.jpg        https://static.miraheze.org/windowswallpaperwiki/1/15/Tulips_%28Windows_7%29.jpg

