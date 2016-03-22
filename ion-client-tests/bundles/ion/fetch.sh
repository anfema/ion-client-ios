#!/bin/bash

bundle="bundle.json.tmp"

echo "[" > "$bundle"

cat bundle-additional.json >> "$bundle"

for subdir in "archives" "collections" "fts" "pages" "media" ; do
  if [ -x "${subdir}/fetch.sh" ] ; then
    echo "Fetching $subdir..."
    pushd "$subdir" &>/dev/null
    "./fetch.sh"
    popd &>/dev/null
  fi

  if [ -e "${subdir}/bundle-part.json" ] ; then
    echo "Adding $subdir/bundle-part.json..."
    cat "${subdir}/bundle-part.json" >> "$bundle"
  fi
done

# remove last comma
head -n $(( $(wc -l "$bundle" |sed -e 's/[ ]*\([0-9]*\) .*/\1/') - 1 )) "$bundle" > bundle.json
echo "  }" >> bundle.json
echo "]" >> bundle.json

rm "$bundle"