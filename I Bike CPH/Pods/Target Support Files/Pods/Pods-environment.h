
// To check if a library is compiled with CocoaPods you
// can use the `COCOAPODS` macro definition which is
// defined in the xcconfigs so it is available in
// headers also when they are imported in the client
// project.


// Bolts
#define COCOAPODS_POD_AVAILABLE_Bolts
#define COCOAPODS_VERSION_MAJOR_Bolts 1
#define COCOAPODS_VERSION_MINOR_Bolts 1
#define COCOAPODS_VERSION_PATCH_Bolts 3

// DAKeyboardControl
#define COCOAPODS_POD_AVAILABLE_DAKeyboardControl
#define COCOAPODS_VERSION_MAJOR_DAKeyboardControl 2
#define COCOAPODS_VERSION_MINOR_DAKeyboardControl 4
#define COCOAPODS_VERSION_PATCH_DAKeyboardControl 0

// Facebook-iOS-SDK
#define COCOAPODS_POD_AVAILABLE_Facebook_iOS_SDK
#define COCOAPODS_VERSION_MAJOR_Facebook_iOS_SDK 3
#define COCOAPODS_VERSION_MINOR_Facebook_iOS_SDK 20
#define COCOAPODS_VERSION_PATCH_Facebook_iOS_SDK 0

// GoogleAnalytics-iOS-SDK
#define COCOAPODS_POD_AVAILABLE_GoogleAnalytics_iOS_SDK
#define COCOAPODS_VERSION_MAJOR_GoogleAnalytics_iOS_SDK 3
#define COCOAPODS_VERSION_MINOR_GoogleAnalytics_iOS_SDK 10
#define COCOAPODS_VERSION_PATCH_GoogleAnalytics_iOS_SDK 0

// TTTAttributedLabel
#define COCOAPODS_POD_AVAILABLE_TTTAttributedLabel
#define COCOAPODS_VERSION_MAJOR_TTTAttributedLabel 1
#define COCOAPODS_VERSION_MINOR_TTTAttributedLabel 10
#define COCOAPODS_VERSION_PATCH_TTTAttributedLabel 1

// UIImage-Categories
#define COCOAPODS_POD_AVAILABLE_UIImage_Categories
#define COCOAPODS_VERSION_MAJOR_UIImage_Categories 0
#define COCOAPODS_VERSION_MINOR_UIImage_Categories 0
#define COCOAPODS_VERSION_PATCH_UIImage_Categories 1

// Debug build configuration
#ifdef DEBUG

  // Reveal-iOS-SDK
  #define COCOAPODS_POD_AVAILABLE_Reveal_iOS_SDK
  #define COCOAPODS_VERSION_MAJOR_Reveal_iOS_SDK 1
  #define COCOAPODS_VERSION_MINOR_Reveal_iOS_SDK 0
  #define COCOAPODS_VERSION_PATCH_Reveal_iOS_SDK 6

#endif