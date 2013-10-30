# Compress

ffmpeg -i bearkoe.mp3 -ab 96 bearkoe.small.mp3

# Compress in directory

find . \ -type file -name "*.mp3" | xargs -I {} ffmpeg -y -i {} -ab 96 {}


# Find all files and copy appending suffix

for file in `find . \ -type file -name "*.jpg"`;
    cp "${file}" "${file:0:${#file} - ${#file##*/}}${${file##*/}%.jpg}-small-mobile.jpg"  ;

for file in `find . \ -type file -name "*.jpg"`;
    cp "${file}" "${file:0:${#file} - ${#file##*/}}${${file##*/}%.jpg}-medium-tablet.jpg"  ;

# Resize

mogrify -resize 200x200 filename.jpg


