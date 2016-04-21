#!/bin/sh

# Copy secret plist files
cp ./secrets/ios/shared/smroute_settings_private.plist ./I\ Bike\ CPH/Shared/Resources/RoutingEngineSettings/smroute_settings_private.plist
cp ./secrets/ios/ibikecph/smroute_settings_app_private.plist ./I\ Bike\ CPH/I\ Bike\ CPH/Resources/smroute_settings_app_private.plist
cp ./secrets/ios/ibikecph/smroute_settings_app_private.plist ./I\ Bike\ CPH/CykelPlanen/Resources/smroute_settings_app_private.plist
