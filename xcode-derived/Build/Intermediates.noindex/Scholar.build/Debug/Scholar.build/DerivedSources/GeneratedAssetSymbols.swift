import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "AppBackground" asset catalog color resource.
    static let appBackground = DeveloperToolsSupport.ColorResource(name: "AppBackground", bundle: resourceBundle)

    /// The "AppBorder" asset catalog color resource.
    static let appBorder = DeveloperToolsSupport.ColorResource(name: "AppBorder", bundle: resourceBundle)

    /// The "AppDivider" asset catalog color resource.
    static let appDivider = DeveloperToolsSupport.ColorResource(name: "AppDivider", bundle: resourceBundle)

    /// The "AppSurface" asset catalog color resource.
    static let appSurface = DeveloperToolsSupport.ColorResource(name: "AppSurface", bundle: resourceBundle)

    /// The "AppSurfaceElevated" asset catalog color resource.
    static let appSurfaceElevated = DeveloperToolsSupport.ColorResource(name: "AppSurfaceElevated", bundle: resourceBundle)

    /// The "AppTextInverse" asset catalog color resource.
    static let appTextInverse = DeveloperToolsSupport.ColorResource(name: "AppTextInverse", bundle: resourceBundle)

    /// The "AppTextPrimary" asset catalog color resource.
    static let appTextPrimary = DeveloperToolsSupport.ColorResource(name: "AppTextPrimary", bundle: resourceBundle)

    /// The "AppTextSecondary" asset catalog color resource.
    static let appTextSecondary = DeveloperToolsSupport.ColorResource(name: "AppTextSecondary", bundle: resourceBundle)

    /// The "AppTextTertiary" asset catalog color resource.
    static let appTextTertiary = DeveloperToolsSupport.ColorResource(name: "AppTextTertiary", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "AppBackground" asset catalog color.
    static var appBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appBackground)
#else
        .init()
#endif
    }

    /// The "AppBorder" asset catalog color.
    static var appBorder: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appBorder)
#else
        .init()
#endif
    }

    /// The "AppDivider" asset catalog color.
    static var appDivider: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appDivider)
#else
        .init()
#endif
    }

    /// The "AppSurface" asset catalog color.
    static var appSurface: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appSurface)
#else
        .init()
#endif
    }

    /// The "AppSurfaceElevated" asset catalog color.
    static var appSurfaceElevated: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appSurfaceElevated)
#else
        .init()
#endif
    }

    /// The "AppTextInverse" asset catalog color.
    static var appTextInverse: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appTextInverse)
#else
        .init()
#endif
    }

    /// The "AppTextPrimary" asset catalog color.
    static var appTextPrimary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appTextPrimary)
#else
        .init()
#endif
    }

    /// The "AppTextSecondary" asset catalog color.
    static var appTextSecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appTextSecondary)
#else
        .init()
#endif
    }

    /// The "AppTextTertiary" asset catalog color.
    static var appTextTertiary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appTextTertiary)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "AppBackground" asset catalog color.
    static var appBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appBackground)
#else
        .init()
#endif
    }

    /// The "AppBorder" asset catalog color.
    static var appBorder: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appBorder)
#else
        .init()
#endif
    }

    /// The "AppDivider" asset catalog color.
    static var appDivider: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appDivider)
#else
        .init()
#endif
    }

    /// The "AppSurface" asset catalog color.
    static var appSurface: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appSurface)
#else
        .init()
#endif
    }

    /// The "AppSurfaceElevated" asset catalog color.
    static var appSurfaceElevated: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appSurfaceElevated)
#else
        .init()
#endif
    }

    /// The "AppTextInverse" asset catalog color.
    static var appTextInverse: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appTextInverse)
#else
        .init()
#endif
    }

    /// The "AppTextPrimary" asset catalog color.
    static var appTextPrimary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appTextPrimary)
#else
        .init()
#endif
    }

    /// The "AppTextSecondary" asset catalog color.
    static var appTextSecondary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appTextSecondary)
#else
        .init()
#endif
    }

    /// The "AppTextTertiary" asset catalog color.
    static var appTextTertiary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .appTextTertiary)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "AppBackground" asset catalog color.
    static var appBackground: SwiftUI.Color { .init(.appBackground) }

    /// The "AppBorder" asset catalog color.
    static var appBorder: SwiftUI.Color { .init(.appBorder) }

    /// The "AppDivider" asset catalog color.
    static var appDivider: SwiftUI.Color { .init(.appDivider) }

    /// The "AppSurface" asset catalog color.
    static var appSurface: SwiftUI.Color { .init(.appSurface) }

    /// The "AppSurfaceElevated" asset catalog color.
    static var appSurfaceElevated: SwiftUI.Color { .init(.appSurfaceElevated) }

    /// The "AppTextInverse" asset catalog color.
    static var appTextInverse: SwiftUI.Color { .init(.appTextInverse) }

    /// The "AppTextPrimary" asset catalog color.
    static var appTextPrimary: SwiftUI.Color { .init(.appTextPrimary) }

    /// The "AppTextSecondary" asset catalog color.
    static var appTextSecondary: SwiftUI.Color { .init(.appTextSecondary) }

    /// The "AppTextTertiary" asset catalog color.
    static var appTextTertiary: SwiftUI.Color { .init(.appTextTertiary) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "AppBackground" asset catalog color.
    static var appBackground: SwiftUI.Color { .init(.appBackground) }

    /// The "AppBorder" asset catalog color.
    static var appBorder: SwiftUI.Color { .init(.appBorder) }

    /// The "AppDivider" asset catalog color.
    static var appDivider: SwiftUI.Color { .init(.appDivider) }

    /// The "AppSurface" asset catalog color.
    static var appSurface: SwiftUI.Color { .init(.appSurface) }

    /// The "AppSurfaceElevated" asset catalog color.
    static var appSurfaceElevated: SwiftUI.Color { .init(.appSurfaceElevated) }

    /// The "AppTextInverse" asset catalog color.
    static var appTextInverse: SwiftUI.Color { .init(.appTextInverse) }

    /// The "AppTextPrimary" asset catalog color.
    static var appTextPrimary: SwiftUI.Color { .init(.appTextPrimary) }

    /// The "AppTextSecondary" asset catalog color.
    static var appTextSecondary: SwiftUI.Color { .init(.appTextSecondary) }

    /// The "AppTextTertiary" asset catalog color.
    static var appTextTertiary: SwiftUI.Color { .init(.appTextTertiary) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

