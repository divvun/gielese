﻿# Compress

ffmpeg -i bearkoe.mp3 -ab 96 bearkoe.small.mp3

# Compress in directory

find . \ -type file -name "*.mp3" | xargs -I {} ffmpeg -y -i {} -ab 96 {}


# Find all files and copy appending suffix
find . \ -type file -name "*.jpg" | grep -v "mobile" | grep -v "tablet" > files.txt

for file in `cat files.txt`;
    do cp "${file}" "${file:0:${#file} - ${#file##*/}}${${file##*/}%.jpg}-medium-tablet.jpg"  ;
done

for file in `cat files.txt`;
    do cp "${file}" "${file:0:${#file} - ${#file##*/}}${${file##*/}%.jpg}-small-mobile.jpg"  ;
done

find . \ -type file -name "*-small-mobile.jpg" | xargs -I {} mogrify -resize 200x200 {}
find . \ -type file -name "*-medium-tablet.jpg" | xargs -I {} mogrify -resize 350x350 {}

rm files.txt

# Resize

mogrify -resize 200x200 filename.jpg


for file in `find . \ -type file -name "*.jpg"`;
    mogrify -resize 200x200 filename.jpg


# Make category backgrounds

find . \ -type file -name "*background-in.jpg" > files.txt

for file in `cat files.txt`;
    do cp "${file}" "${file:0:${#file} - ${#file##*/}}${${file##*/}%-in.jpg}-large.jpg"  ;
done

for file in `cat files.txt`;
    do cp "${file}" "${file:0:${#file} - ${#file##*/}}${${file##*/}%-in.jpg}.jpg"  ;
done

find . \ -type file -name "*-background.jpg" | xargs -I {} mogrify -resize 440x440 {}
find . \ -type file -name "*-background-large.jpg" | xargs -I {} mogrify -resize 768x768 {}

rm files.txt
