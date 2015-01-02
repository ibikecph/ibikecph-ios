# iOS apps for I Bike CPH + CykelPlanen 

## Dependencies
### CocoaPods
[CocoaPods](http://cocoapods.org) is used for most 3rd party dependencies. The pods are commited to the repository, so there is no need to install Cocoapods to build and run the project. To update the pods see [here](http://guides.cocoapods.org/using/getting-started.html) for instructions. 
### Git Submodules
Dependencies that don't support CocoaPods, are added as submodules. Most notable are [Route-Me](https://github.com/ibikecph/route-me) [routing-engine](https://github.com/ibikecph/routing-engine).

## I Bike CPH vs. CykelPlanen
### Structure
The two apps are handled as different targets in the same Xcode project. Most code is shared between the two.
### Content
The functionality of the two apps are different.
