#!/bin/bash

collection="test"
username="admin@anfe.ma"
password="test"

rm bundle-part.json

(
file="$collection.sqlite3"
curl -u "${username}:${password}" "http://127.0.0.1:8000/protected_media/fts/${collection}.sqlite3" > $file 2>/dev/null

cat <<EOF
  {
    "request": {
      "method": "GET",
      "url": "://127.0.0.1:8000/protected_media/fts/${collection}.sqlite3"
    },
    "response" : {
      "code": 200,
      "file": "fts/${file}",
      "mime_type": "application/octet-stream"
    }
  },
EOF
) >bundle-part.json