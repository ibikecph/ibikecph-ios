# iOS apps for I Bike CPH + CykelPlanen 

## Dependencies
### CocoaPods
[CocoaPods](http://cocoapods.org) is used for most 3rd party dependencies. The pods are commited to the repository, so there is no need to install Cocoapods to build and run the project. To update the pods see [here](http://guides.cocoapods.org/using/getting-started.html) for instructions.

## Submodules
The repository has a single git submodule containing the localization files used between all I Bike CPH apps. To initialize/add git submodules:

`$ git submodule update --init`

### Enable/disable tracking features
To enabled tracking features you must do two things:
1. Define the following Objective-C preprocessor macro in `ibikecph-ios/I Bike CPH/Shared/SharedConstants.h`: `#define TRACKING_ENABLED 1`
2. Make sure the following custom Swift compiler flag is present in the build settings for each app target: `-D TRACKING_ENABLED`

To disable tracking features you must do two things:
1. Define the following Objective-C preprocessor macro in `ibikecph-ios/I Bike CPH/Shared/SharedConstants.h`: `#define TRACKING_ENABLED 0`
2. Make sure the following custom Swift compiler flag is **NOT** present in the build settings for any app target: `-D TRACKING_ENABLED`

## API secrets/login
In order for the apps to work properly they must be provided with working API secrets/login for FourSquare, Kortforsyningen and an accompanying Facebook app.

### FourSquare and Kortforsyningen
The file `EXAMPLE_smroute_settings_private.plist` must be used as a basis for a file called `smroute_settings_private.plist` in the same location. This file shall contain ID and secret for FourSquare's API as well as username and password for Kortforsyningen's API.

### Facebook
The file `EXAMPLE_smroute_settings_app_private.plist` must be used as a basis for a file called `smroute_settings_app_private.plist` in the same location. This file shall contain the App ID for an accompanying Facebook app.

## I Bike CPH vs. CykelPlanen
### Structure
The two apps are handled as different targets in the same Xcode project. Most code is shared between the two.
### Content
The functionality of the two apps is different.
