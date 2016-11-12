#!/bin/sh

FFDIR=$1

if [[ x$FFDIR == x || $FFDIR == -* ]]; then
  echo "Usage: ./init.sh path-to-firefox-directory"
  exit
fi

rm    -rf chrome/omni-files _classic
mkdir -p  chrome/omni-files _classic

cp $FFDIR/omni.ja         chrome/root-omni.ja &&
cp $FFDIR/browser/omni.ja chrome/browser-omni.ja || exit 1

# extract the top level omni.ja archive
cd chrome/omni-files || exit 1
mv ../root-omni.ja .
unzip -qq root-omni.ja

mv chrome/toolkit/skin/classic/{global,mozapps} ../

# empty the omni-files dir before extracting second archive
rm -r ./*
mv ../browser-omni.ja .
unzip -qq browser-omni.ja

mv chrome/browser/skin/classic/{browser,communicator} ../

for dir in devtools webide; {
  mv chrome/$dir/skin ../$dir
}

cd ..
rm -rf omni-files

# create directories in "classic" for the original CSS files
find . -type d -print0 | xargs -0 -I{} mkdir -p ../_classic/{}


# find all the original CSS files
find browser communicator devtools global mozapps webide -type f -name "*.css" -print0 | \
  # move original CSS files to "_classic" and prefix them with "_"
  # create corresponding CSS files with @import to their _classic files
  xargs -0 -I{} echo mv {} ../_classic/{}\; echo @import \'{}\' ">" {} | \
  # prefix _classic filenames with "_" and change ext to .scss (before ;)
  sed 's/\/\([^/]*\)[.]css;/\/_\1.scss;/' | \
  # mv global/global.css ../_classic/global/_global.scss; echo @import 'global/global.css' > global/global.css
  # remove .css from @import targets
  sed 's/\([^/]*\)[.]css/\1/2' | \
  # mv global/global.css ../_classic/global/_global.scss; echo @import 'global/global' > global/global.css
  # change file extension at the end ($) to scss
  sed 's/[.]css$/.scss/' | \
  # mv global/global.css ../_classic/global/_global.scss; echo @import 'global/global' > global/global.scss
  bash

cd ..

# delete empty dicectories in _classic
find _classic -type d -empty -delete

# write chrome.manifest
echo \
"skin browser      sample chrome/browser/
skin communicator sample chrome/communicator/
skin devtools     sample chrome/devtools/
skin global       sample chrome/global/
skin mozapps      sample chrome/mozapps/
skin webide       sample chrome/webide/
" > chrome.manifest

echo DONE!
