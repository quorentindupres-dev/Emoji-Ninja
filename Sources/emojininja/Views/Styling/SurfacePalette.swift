// One home for the colors, styles, shapes, visual effect glass, and card chrome the reusable surfaces share.
// Components/ must not import a live window file, and must not depend on the host app's
// Color(hex:) extension: the folder is meant to be copied into another Swift app.
// Keep new surface helpers here.
// Coucou palette: high #F29B38, medium #2DD4BF, low #8E939C, surface #141518.
import AppKit
import SwiftUI

public extension Color {
    init(surfaceHex hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = Int(cleaned, radix: 16) else {
            self = .clear
            return
        }
        self = Color(
            .sRGB,
            red: Double((value >> 16) & 0xff) / 255,
            green: Double((value >> 8) & 0xff) / 255,
            blue: Double(value & 0xff) / 255,
            opacity: 1
        )
    }
}

public func surfaceColor(_ hex: String) -> Color {
    Color(surfaceHex: hex)
}

/// Canonical Coucou priority hex for radial washes and accents.
public func pulseHex(_ value: String) -> String {
    let text = value.lowercased()
    if text.contains("urgent") || text.contains("p0") || text.contains("high") {
        return "#F29B38"
    }
    if text.contains("medium") {
        return "#2DD4BF"
    }
    if text.contains("low") {
        return "#8E939C"
    }
    return "#F29B38"
}

/// One priority color for the chip, the capsule, the notch pop, and the island header.
public func pulseColor(_ value: String) -> Color {
    surfaceColor(pulseHex(value))
}

/// Checks macOS Reduce Motion preference without requiring a SwiftUI view environment.
@MainActor
public func surfaceReduceMotion() -> Bool {
    NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
}

// MARK: - DN-01: SurfaceStyle & Concentric Corner Geometry

/// Defines the visual presentation and corner geometry of a surface, rebuilt from `DynamicNotchStyle.swift`.
/// Enforces concentric corner math: `Outer Radius = Inner Radius + Padding`.
public enum SurfaceStyle: Equatable, Sendable {
    case notch(topCornerRadius: CGFloat, bottomCornerRadius: CGFloat)
    case floating(cornerRadius: CGFloat)
    case glass(cornerRadius: CGFloat)
    case auto

    /// Preset notch style (`top: 15, bottom: 20`).
    public static let notch: SurfaceStyle = .notch(topCornerRadius: 15, bottomCornerRadius: 20)

    /// Preset floating card style (`cornerRadius: 20`).
    public static let floating: SurfaceStyle = .floating(cornerRadius: 20)

    /// Preset glass popover style (`cornerRadius: 20`).
    public static let glass: SurfaceStyle = .glass(cornerRadius: 20)

    /// Concentric corner radius formula (`Outer Radius = Inner Radius + Padding`), clamped to `minimum`.
    public static func concentricInnerRadius(
        outerRadius: CGFloat,
        padding: CGFloat,
        minimum: CGFloat = 6
    ) -> CGFloat {
        max(minimum, outerRadius - padding)
    }

    public var isNotch: Bool {
        if case .notch = self { return true }
        return false
    }

    public var isFloating: Bool {
        switch self {
        case .floating, .glass:
            return true
        case .notch, .auto:
            return false
        }
    }

    public var cornerRadius: CGFloat {
        switch self {
        case let .notch(_, bottomCornerRadius):
            return bottomCornerRadius
        case let .floating(cornerRadius), let .glass(cornerRadius):
            return cornerRadius
        case .auto:
            return 20
        }
    }
}

/// Namespace for shared palette and concentric geometry helpers.
public enum SurfacePalette {
    public static func concentricInnerRadius(
        outerRadius: CGFloat,
        padding: CGFloat,
        minimum: CGFloat = 6
    ) -> CGFloat {
        SurfaceStyle.concentricInnerRadius(outerRadius: outerRadius, padding: padding, minimum: minimum)
    }
}

// MARK: - DN-02: SurfaceNotchShape (Quad-Curve Hardware Notch Silhouette)

/// Quad-curve hardware notch silhouette with animatable top ear and bottom corner radii,
/// rebuilt from `DynamicNotchKit/Views/NotchShape.swift`.
public struct SurfaceNotchShape: Shape, Sendable {
    public var topCornerRadius: CGFloat
    public var bottomCornerRadius: CGFloat

    public static let compact = SurfaceNotchShape(topCornerRadius: 6, bottomCornerRadius: 14)
    public static let expanded = SurfaceNotchShape(topCornerRadius: 15, bottomCornerRadius: 20)

    public init(
        topCornerRadius: CGFloat = 15,
        bottomCornerRadius: CGFloat = 20
    ) {
        self.topCornerRadius = topCornerRadius
        self.bottomCornerRadius = bottomCornerRadius
    }

    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            .init(topCornerRadius, bottomCornerRadius)
        }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.minY + topCornerRadius
            ),
            control: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.maxY - bottomCornerRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX + topCornerRadius + bottomCornerRadius,
                y: rect.maxY
            ),
            control: CGPoint(
                x: rect.minX + topCornerRadius,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - topCornerRadius - bottomCornerRadius,
                y: rect.maxY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.maxY - bottomCornerRadius
            ),
            control: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.minY + topCornerRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX,
                y: rect.minY
            ),
            control: CGPoint(
                x: rect.maxX - topCornerRadius,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        return path
    }
}

// MARK: - DN-03: SurfaceVisualEffectView & Minimalist Glass SurfaceCardChrome

/// Native macOS `NSVisualEffectView` wrapper rebuilt from `DynamicNotchKit/Utility/VisualEffectView.swift`.
public struct SurfaceVisualEffectView: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var isEmphasized: Bool

    public init(
        material: NSVisualEffectView.Material = .popover,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        isEmphasized: Bool = true
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.isEmphasized = isEmphasized
    }

    public func makeNSView(context _: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        visualEffectView.isEmphasized = isEmphasized
        return visualEffectView
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context _: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
        nsView.isEmphasized = isEmphasized
    }
}

/// Minimalist native dark glass & Coucou card surface grammar:
/// optional `SurfaceVisualEffectView` (`.popover`, `.behindWindow`) beneath `#141518` base tint (`0.94` opacity),
/// subtle radial state wash (`0.16` opacity) at `UnitPoint(x: 0.5, y: 1.3)`, and plain borderless edges (`strokeOpacity: 0.0`) like Coucou.
public struct SurfaceCardChrome: View {
    public var cornerRadius: CGFloat
    public var fill: String
    public var fillOpacity: Double
    public var washHex: String
    public var washOpacity: Double
    public var strokeHex: String
    public var strokeOpacity: Double
    public var useGlass: Bool

    public init(
        cornerRadius: CGFloat = 20,
        fill: String = "#141518",
        fillOpacity: Double = 0.94,
        washHex: String = "#F29B38",
        washOpacity: Double = 0.16,
        strokeHex: String = "#FFFFFF",
        strokeOpacity: Double = 0.0,
        useGlass: Bool = true
    ) {
        self.cornerRadius = cornerRadius
        self.fill = fill
        self.fillOpacity = fillOpacity
        self.washHex = washHex
        self.washOpacity = washOpacity
        self.strokeHex = strokeHex
        self.strokeOpacity = strokeOpacity
        self.useGlass = useGlass
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            if useGlass {
                SurfaceVisualEffectView(material: .popover, blendingMode: .behindWindow)
                    .clipShape(shape)
            }
            shape
                .fill(surfaceColor(fill).opacity(fillOpacity))
                .overlay(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: surfaceColor(washHex).opacity(washOpacity), location: 0),
                            .init(color: .clear, location: 0.72),
                        ]),
                        center: UnitPoint(x: 0.5, y: 1.3),
                        startRadius: 0,
                        endRadius: 260
                    )
                    .clipShape(shape)
                )
                .overlay(
                    Group {
                        if strokeOpacity > 0 {
                            shape.stroke(surfaceColor(strokeHex).opacity(strokeOpacity), lineWidth: 1)
                        }
                    }
                )
        }
    }
}

public extension View {
    func surfaceCardChrome(
        cornerRadius: CGFloat = 20,
        fill: String = "#141518",
        fillOpacity: Double = 0.94,
        washHex: String = "#F29B38",
        washOpacity: Double = 0.16,
        strokeHex: String = "#FFFFFF",
        strokeOpacity: Double = 0.0,
        useGlass: Bool = true
    ) -> some View {
        background(
            SurfaceCardChrome(
                cornerRadius: cornerRadius,
                fill: fill,
                fillOpacity: fillOpacity,
                washHex: washHex,
                washOpacity: washOpacity,
                strokeHex: strokeHex,
                strokeOpacity: strokeOpacity,
                useGlass: useGlass
            )
        )
    }
}
