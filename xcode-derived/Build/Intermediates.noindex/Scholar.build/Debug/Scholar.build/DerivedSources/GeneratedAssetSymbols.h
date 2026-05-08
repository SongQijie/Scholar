#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"local.Scholar";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "AppBackground" asset catalog color resource.
static NSString * const ACColorNameAppBackground AC_SWIFT_PRIVATE = @"AppBackground";

/// The "AppBorder" asset catalog color resource.
static NSString * const ACColorNameAppBorder AC_SWIFT_PRIVATE = @"AppBorder";

/// The "AppDivider" asset catalog color resource.
static NSString * const ACColorNameAppDivider AC_SWIFT_PRIVATE = @"AppDivider";

/// The "AppSurface" asset catalog color resource.
static NSString * const ACColorNameAppSurface AC_SWIFT_PRIVATE = @"AppSurface";

/// The "AppSurfaceElevated" asset catalog color resource.
static NSString * const ACColorNameAppSurfaceElevated AC_SWIFT_PRIVATE = @"AppSurfaceElevated";

/// The "AppTextInverse" asset catalog color resource.
static NSString * const ACColorNameAppTextInverse AC_SWIFT_PRIVATE = @"AppTextInverse";

/// The "AppTextPrimary" asset catalog color resource.
static NSString * const ACColorNameAppTextPrimary AC_SWIFT_PRIVATE = @"AppTextPrimary";

/// The "AppTextSecondary" asset catalog color resource.
static NSString * const ACColorNameAppTextSecondary AC_SWIFT_PRIVATE = @"AppTextSecondary";

/// The "AppTextTertiary" asset catalog color resource.
static NSString * const ACColorNameAppTextTertiary AC_SWIFT_PRIVATE = @"AppTextTertiary";

#undef AC_SWIFT_PRIVATE
