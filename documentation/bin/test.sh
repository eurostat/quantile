#!/bin/bash

beg=\#STARTDOC
end=\#ENDDOC

echo $beg 

file=/cygdrive/z/5.3_Validation/pgm/data_extract.R
filename=$(basename "$file")
echo $filename
extension="${filename##*.}"
filename="${filename%.*}"
echo $filename $extension 

awk 'NF==0&&s==0{NR=0}NR==1&&$1=="#STARTDOC"{s=1}s==1{print $0}$NF=="#ENDDOC"{s=2}' $file | awk '!/^ *\#STARTDOC/ { print; }' - | awk '!/^ *\#ENDDOC/ { print substr($0,2); }'

sed '1,/`echo $beg`/d;/`echo $end`/,$d' /cygdrive/z/5.3_Validation/pgm/data_extract.R
sed -i "1,/${beg}/d;/${end}/,$d" /cygdrive/z/5.3_Validation/pgm/data_extract.R
sed "1,/$(echo $beg)/d;/$(echo $end)/,$d" /cygdrive/z/5.3_Validation/pgm/data_extract.R
sed '/$beg/,/$end/!d;//d'

awk '
  $1 == "secondmatch" {print_me = 0}
  print_me {print}
  $1 == "firstmatch {print_me = 1}
'