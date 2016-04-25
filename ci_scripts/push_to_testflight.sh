#!/bin/sh
if [[ "$TRAVIS_PULL_REQUEST" == "false" && "$TRAVIS_BRANCH" == "ci-testflight" ]]; then
  echo "********************"
  echo "*     Uploading    *"
  echo "********************"

  deliver -a "$BUNDLE_IDENTIFIER_0" -i "$OUTPUTDIR/$APP_NAME_0.ipa" -m "$METADATA_PATH_0"
  deliver -a "$BUNDLE_IDENTIFIER_1" -i "$OUTPUTDIR/$APP_NAME_1.ipa" -m "$METADATA_PATH_1"
else
  echo "Building on a branch other than ci-testflight or from a pull request. No deployment will be done."
fi
