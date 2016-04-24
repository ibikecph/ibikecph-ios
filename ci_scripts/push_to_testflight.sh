#!/bin/sh
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  echo "This is a pull request. No deployment will be done."
  exit 0
fi
if [[ "$TRAVIS_BRANCH" != "ci-test" ]]; then
  echo "Testing on a branch other than develop. No deployment will be done."
  exit 0
fi

echo "********************"
echo "*     Uploading    *"
echo "********************"

deliver --ipa "$OUTPUTDIR/$APP_NAME.ipa"
