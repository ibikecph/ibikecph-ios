#!/bin/sh
if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  echo "This is a pull request. No deployment will be done."
  exit 0
fi
if [[ "$TRAVIS_BRANCH" != "ci-test" ]]; then
  echo "Testing on a branch other than develop. No deployment will be done."
  exit 0
fi

PROVISIONING_PROFILE="$HOME/Library/MobileDevice/Provisioning Profiles/$prov_profile_name.mobileprovision"
RELEASE_DATE=`date '+%Y-%m-%d %H:%M:%S'`
OUTPUTDIR="$PWD/build/Release-iphoneos"

echo "********************"
echo "*     Signing      *"
echo "********************"
xcrun -log -sdk iphoneos PackageApplication "$OUTPUTDIR/$app_name.app" -o "$OUTPUTDIR/$app_name.ipa" -sign "$developer_name" -embed "$PROVISIONING_PROFILE"

# RELEASE_NOTES="Build: $TRAVIS_BUILD_NUMBER\nUploaded: $RELEASE_DATE"
# 
# zip -r -9 "$OUTPUTDIR/$app_name.app.dSYM.zip" "$OUTPUTDIR/$app_name.app.dSYM"
# 
# echo "********************"
# echo "*    Uploading     *"
# echo "********************"
# curl http://testflightapp.com/api/builds.json \
#   -F file="@$OUTPUTDIR/$app_name.ipa" \
#   -F dsym="@$OUTPUTDIR/$app_name.app.dSYM.zip" \
#   -F api_token="$API_TOKEN" \
#   -F team_token="$TEAM_TOKEN" \
#   -F distribution_lists='Internal' \
#   -F notes="$RELEASE_NOTES" -v
