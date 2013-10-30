for file in `find . \ -type file -name "*.jpg"` ;
    echo "something ${file}" ; # ${${file##*/}%.jpg}}"
endfor

