#!/bin/bash

collection="test"
username="admin@anfe.ma"
password="test"

rm bundle-part.json

(
for lang in "en_US" "de_DE" ; do

    for variation in "@2x" "@3x" "default" ; do

        file="$collection-$lang-$variation.tar"
        curl -v -u "${username}:${password}" "http://127.0.0.1:8000/client/v1/${lang}/${collection}.tar?variation=${variation}" > $file

cat <<EOF
  {
    "request": {
      "method": "GET",
      "url": "://127.0.0.1:8000/client/v1/${lang}/${collection}.tar",
      "parameters": {
        "variation": "${variation}"
      }
    },
    "response" : {
      "code": 200,
      "file": "archives/${file}",
      "mime_type": "application/x-tar"
    }
  },
  {
    "request": {
      "method": "GET",
      "url": "://127.0.0.1:8000/client/v1/${lang}/${collection}.tar",
      "parameters": {
        "variation": "${variation}",
        "lastUpdated": null
      }
    },
    "response" : {
      "code": 200,
      "file": "archives/${file}",
      "mime_type": "application/x-tar"
    }
  },
EOF

    done

done
) >bundle-part.json