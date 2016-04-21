#!/bin/sh

# Decrypt secret files
openssl aes-256-cbc -k "$file_enc_password" -in secrets/ios/certs/distribution.cer.enc -out secrets/ios/certs/distribution.cer -d
openssl aes-256-cbc -k "$file_enc_password" -in secrets/ios/certs/distribution.p12.enc -out secrets/ios/certs/distribution.p12 -d
openssl aes-256-cbc -k "$file_enc_password" -in secrets/ios/profile/ibikecph_ad_hoc.mobileprovision.enc -out secrets/ios/profile/ibikecph_ad_hoc.mobileprovision -d
openssl aes-256-cbc -k "$file_enc_password" -in secrets/ios/profile/cykelplanen_ad_hoc.mobileprovision.enc -out secrets/ios/profile/cykelplanen_ad_hoc.mobileprovision -d
openssl aes-256-cbc -k "$file_enc_password" -in secrets/ios/shared/smroute_settings_private.plist.enc -out secrets/ios/shared/smroute_settings_private.plist -d
openssl aes-256-cbc -k "$file_enc_password" -in secrets/ios/ibikecph/smroute_settings_app_private.plist.enc -out secrets/ios/ibikecph/smroute_settings_app_private.plist -d
openssl aes-256-cbc -k "$file_enc_password" -in secrets/ios/cykelplanen/smroute_settings_app_private.plist.enc -out secrets/ios/cykelplanen/smroute_settings_app_private.plist -d
