# iOS apps for I Bike CPH + CykelPlanen 

## Dependencies
### CocoaPods
[CocoaPods](http://cocoapods.org) is used for most 3rd party dependencies. The pods are commited to the repository, so there is no need to install Cocoapods to build and run the project. To update the pods see [here](http://guides.cocoapods.org/using/getting-started.html) for instructions. 

### Git Submodules
Dependencies that don't support CocoaPods are added as submodules. 
These are [strings](https://github.com/ibikecph/strings) and [routing-engine](https://github.com/ibikecph/routing-engine).

### Enable/disable tracking features
To enabled tracking features you must do two things:
1. Define the following Objective-C preprocessor macro in `ibikecph-ios/I Bike CPH/Shared/SharedConstants.h`: `#define TRACKING_ENABLED 1`
2. Make sure the following custom Swift compiler flag is present in the build settings for each app target: `-D TRACKING_ENABLED`

To disable tracking features you must do two things:
1. Define the following Objective-C preprocessor macro in `ibikecph-ios/I Bike CPH/Shared/SharedConstants.h`: `#define TRACKING_ENABLED 0`
2. Make sure the following custom Swift compiler flag is **NOT** present in the build settings for any app target: `-D TRACKING_ENABLED`


## I Bike CPH vs. CykelPlanen
### Structure
The two apps are handled as different targets in the same Xcode project. Most code is shared between the two.
### Content
The functionality of the two apps is different.
