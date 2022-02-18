#!/bin/bash

(
for page in $(ls -1 ../pages/*.json) ; do
	links=$(cat "../pages/${page}" |tr ',' "\n"|sed -e '/protected_media/!d' -e 's@.*"http://\([^"]*\)".*@://\1@')

	for link in $links ; do
		last_part=$(echo $link|sed -e 's@.*protected_media.*/\([^_]*\)_*[^.]*\.\(.*\)@\1.\2@')

		if [ -e "$last_part" ] ; then
			mime=$(file -b --mime-type "$last_part")
cat <<EOF
  {
    "request": {
      "method": "GET",
      "url": "$link"
    },
    "response" : {
      "code": 200,
      "file": "media/${last_part}",
      "mime_type": "${mime}"
    }
  },
EOF
		else
			echo "$last_part is missing!" >&2
		fi

	done	
done
) >bundle-part.json