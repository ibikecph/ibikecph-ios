#!/bin/sh
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  echo "This is a pull request. No deployment will be done."
  exit 0
fi
if [[ "$TRAVIS_BRANCH" != "ci-testflight" ]]; then
  echo "Building on a branch other than ci-testflight. No deployment will be done."
  exit 0
fi

echo "********************"
echo "*     Uploading    *"
echo "********************"

deliver -a "$BUNDLE_IDENTIFIER_0" -i "$OUTPUTDIR/$APP_NAME_0.ipa" -m "$METADATA_PATH_0"
deliver -a "$BUNDLE_IDENTIFIER_1" -i "$OUTPUTDIR/$APP_NAME_1.ipa" -m "$METADATA_PATH_1"
