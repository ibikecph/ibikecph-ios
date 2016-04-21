#!/bin/sh

# Decrypt secret files
echo $file_enc_password | gpg --passphrase-fd 0 secrets/ios/certs/distribution.cer.gpg
echo $file_enc_password | gpg --passphrase-fd 0 secrets/ios/certs/distribution.p12.gpg
echo $file_enc_password | gpg --passphrase-fd 0 secrets/ios/profile/cykelplanen_ad_hoc.mobileprovision.gpg
echo $file_enc_password | gpg --passphrase-fd 0 secrets/ios/profile/ibikecph_ad_hoc.mobileprovision.gpg
echo $file_enc_password | gpg --passphrase-fd 0 secrets/ios/shared/smroute_settings_private.plist.gpg
echo $file_enc_password | gpg --passphrase-fd 0 secrets/ios/ibikecph/smroute_settings_app_private.plist.gpg
echo $file_enc_password | gpg --passphrase-fd 0 secrets/ios/cykelplanen/smroute_settings_app_private.plist.gpg
