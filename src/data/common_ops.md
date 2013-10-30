# Compress

ffmpeg -i bearkoe.mp3 -ab 96 bearkoe.small.mp3

# Compress in directory

find . \ -type file -name "*.mp3" | xargs -I {} ffmpeg -y -i {} -ab 96 {}


# Find all files and copy appending suffix
find . \ -type file -name "*.jpg" > files.txt

for file in `cat files.txt`;
    do cp "${file}" "${file:0:${#file} - ${#file##*/}}${${file##*/}%.jpg}-medium-tablet.jpg"  ;
done

for file in `cat files.txt`;
    do cp "${file}" "${file:0:${#file} - ${#file##*/}}${${file##*/}%.jpg}-small-mobile.jpg"  ;
done

find . \ -type file -name "*-small-mobile.jpg" | xargs -I {} mogrify -resize 200x200 {}
find . \ -type file -name "*-medium-tablet.jpg" | xargs -I {} mogrify -resize 350x350 {}

# Resize

mogrify -resize 200x200 filename.jpg


for file in `find . \ -type file -name "*.jpg"`;
    mogrify -resize 200x200 filename.jpg
