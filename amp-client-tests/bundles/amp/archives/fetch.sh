#!/bin/bash

collection="test"
username="admin@anfe.ma"
password="test"

rm bundle-part.json

(
for lang in "en_US" "de_DE" ; do

    for variation in "@2x" "@3x" "default" ; do

        file="$collection-$lang-$variation.tar"
        curl -u "${username}:${password}" "http://127.0.0.1:8000/client/v1/archive/${collection}?locale=${lang}&variation=${variation}" > $file 2>/dev/null

cat <<EOF
  {
    "request": {
      "method": "GET",
      "url": "://127.0.0.1:8000/client/v1/archive/${collection}",
      "parameters": {
        "locale": "${lang}",
        "variation": "${variation}"
      }
    },
    "response" : {
      "code": 200,
      "file": "archives/${file}",
      "mime_type": "application/json"
    }
  },
  {
    "request": {
      "method": "GET",
      "url": "://127.0.0.1:8000/client/v1/archive/${collection}",
      "parameters": {
        "locale": "${lang}",
        "variation": "${variation}",
        "lastUpdate": null
      }
    },
    "response" : {
      "code": 200,
      "file": "archives/${file}",
      "mime_type": "application/json"
    }
  },
EOF

    done

done
) >bundle-part.json