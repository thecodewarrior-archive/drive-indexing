#!/bin/sh

dir=${1:-$(dirname "$0")}

cd "$dir"


comp="compiled.cdindex"

touch "$comp"
rm "$comp"
touch "$comp"

find Listings -name "*.dindex" -print | while read file
do
  first=1
  cat "$file" | while read line
  do
    if [ $first -eq 1 ]
    then
      echo $line
      echo "$line {" >> "$comp"
      first=0
    else
      echo $line >> "$comp"
    fi
  done
  echo "}" >> "$comp"
done

#v 1.0