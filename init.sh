#!/bin/sh

FFDIR=$1

if [[ x$FFDIR == x || $FFDIR == -* ]]; then
  echo "Usage: ./init.sh path-to-firefox-directory"
  exit
fi

rm    -rf _classic
mkdir -p  _classic/omni-files chrome

cp $FFDIR/omni.ja         _classic/root-omni.ja &&
cp $FFDIR/browser/omni.ja _classic/browser-omni.ja || exit 1

# extract the top level omni.ja archive
cd _classic/omni-files || exit 1
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

# create directories in "chrome" for @imports to the original styles
find . -type d -print0 | xargs -0 -I{} mkdir -p ../chrome/{}


# find all the original CSS files
find browser communicator devtools global mozapps webide -type f -name "*.css" -print0 | \
  # move original CSS files to "_classic" and prefix them with "_"
  # create corresponding CSS files with @import to their _classic files
  xargs -0 -I{} echo "mv {} '{}' ; [[ -f ../chrome/'{}' ]] || { echo @import \'{}\'\; > ../chrome/'{}'; }" | \
  # change appropriate .css to .scss
  sed "s/[.]css'/.scss'/g" | \
  # prefix _classic filenames with "_"
  sed 's/\/\([^/]*\)[.]scss/\/_\1.scss/' | \
  # remove .css from @import targets
  sed 's/[.]css[\]/\\/' | \
  # mv x.css global/_global.scss; [[ -f "../chrome/x.scss" ]] || { echo @import \'x\'\; > ../chrome/"x.scss"; }
  bash

cd ..

# delete empty dicectories in _classic
#find _classic chrome -type d -empty -delete

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
