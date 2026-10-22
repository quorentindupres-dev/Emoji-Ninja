import SwiftUI

// MARK: - Theme Protocol
protocol Theme {
  var colors: ColorScheme { get }
  var typography: Typography { get }
  var spacing: Spacing { get }
  var cornerRadius: CornerRadius { get }
  var shadows: Shadows { get }
}

// MARK: - Color Scheme
struct ColorScheme {
  let background: Color
  let surface: Color
  let surfaceElevated: Color
  let primary: Color
  let secondary: Color
  let accent: Color
  let text: TextColors
  let border: BorderColors
  let semantic: SemanticColors
}

struct TextColors {
  let primary: Color
  let secondary: Color
  let tertiary: Color
  let inverse: Color
  let disabled: Color
}

struct BorderColors {
  let primary: Color
  let secondary: Color
  let selected: Color
  let hover: Color
  let focus: Color
}

struct SemanticColors {
  let success: Color
  let warning: Color
  let error: Color
  let info: Color
}

// MARK: - Typography
struct Typography {
  let largeTitle: Font
  let title: Font
  let headline: Font
  let subheadline: Font
  let body: Font
  let caption: Font
  let caption2: Font
  let emoji: EmojiTypography
}

struct EmojiTypography {
  let small: Font
  let medium: Font
  let large: Font
  let extraLarge: Font
}

// MARK: - Spacing
struct Spacing {
  let xs: CGFloat  // 4
  let small: CGFloat  // 8
  let medium: CGFloat  // 16
  let large: CGFloat  // 24
  let xl: CGFloat  // 32
  let xxl: CGFloat  // 48
}

// MARK: - Corner Radius
struct CornerRadius {
  let small: CGFloat  // 4
  let medium: CGFloat  // 8
  let large: CGFloat  // 12
  let xl: CGFloat  // 16
  let pill: CGFloat  // 999
}

// MARK: - Shadows
struct Shadows {
  let small: ShadowStyle
  let medium: ShadowStyle
  let large: ShadowStyle
}

struct ShadowStyle {
  let color: Color
  let radius: CGFloat
  let xOffset: CGFloat
  let yOffset: CGFloat
}

// MARK: - Dark Theme Implementation
struct DarkTheme: Theme {
  let colors = ColorScheme(
    background: surfaceColor("#141518"),
    surface: surfaceColor("#2B2D31").opacity(0.55),
    surfaceElevated: surfaceColor("#2B2D31"),
    primary: surfaceColor("#F5F6F8"),
    secondary: surfaceColor("#B9BDC4"),
    accent: surfaceColor("#2DD4BF"),
    text: TextColors(
      primary: surfaceColor("#F5F6F8"),
      secondary: surfaceColor("#B9BDC4"),
      tertiary: Color.white.opacity(0.5),
      inverse: surfaceColor("#141518"),
      disabled: surfaceColor("#8E939C").opacity(0.6)
    ),
    border: BorderColors(
      primary: Color.white.opacity(0.08),
      secondary: Color.white.opacity(0.06),
      selected: surfaceColor("#2DD4BF"),
      hover: Color.white.opacity(0.16),
      focus: surfaceColor("#2DD4BF")
    ),
    semantic: SemanticColors(
      success: surfaceColor("#2DD4BF"),
      warning: surfaceColor("#F29B38"),
      error: surfaceColor("#F87171"),
      info: surfaceColor("#2DD4BF")
    )
  )

  let typography = Typography(
    largeTitle: .system(size: 26, weight: .bold),
    title: .system(size: 15, weight: .semibold),
    headline: .system(size: 13, weight: .semibold),
    subheadline: .system(size: 12, weight: .semibold),
    body: .system(size: 13, weight: .regular),
    caption: .system(size: 11, weight: .regular),
    caption2: .system(size: 10.5, weight: .semibold),
    emoji: EmojiTypography(
      small: .system(size: 15),
      medium: .system(size: 20),
      large: .system(size: 28),
      extraLarge: .system(size: 40)
    )
  )

  let spacing = Spacing(
    xs: 4,
    small: 8,
    medium: 16,
    large: 24,
    xl: 32,
    xxl: 48
  )

  let cornerRadius = CornerRadius(
    small: SurfaceStyle.concentricInnerRadius(outerRadius: 20, padding: 14),
    medium: SurfaceStyle.concentricInnerRadius(outerRadius: 20, padding: 10),
    large: 14,
    xl: SurfaceStyle.floating.cornerRadius,
    pill: 999
  )

  let shadows = Shadows(
    small: ShadowStyle(
      color: Color.black.opacity(0.1),
      radius: 2,
      xOffset: 0,
      yOffset: 1
    ),
    medium: ShadowStyle(
      color: Color.black.opacity(0.15),
      radius: 4,
      xOffset: 0,
      yOffset: 2
    ),
    large: ShadowStyle(
      color: Color.black.opacity(0.2),
      radius: 8,
      xOffset: 0,
      yOffset: 4
    )
  )
}

// MARK: - Light Theme Implementation
struct LightTheme: Theme {
  let colors = ColorScheme(
    background: Color(red: 232 / 255, green: 232 / 255, blue: 232 / 255),
    surface: Color.white,
    surfaceElevated: Color.white,
    primary: Color.black,
    secondary: Color(red: 100 / 255, green: 100 / 255, blue: 100 / 255),
    accent: surfaceColor("#2DD4BF"),
    text: TextColors(
      primary: Color.black,
      secondary: Color(red: 100 / 255, green: 100 / 255, blue: 100 / 255),
      tertiary: Color(red: 150 / 255, green: 150 / 255, blue: 150 / 255),
      inverse: Color.white,
      disabled: Color(red: 180 / 255, green: 180 / 255, blue: 180 / 255)
    ),
    border: BorderColors(
      primary: Color(red: 200 / 255, green: 200 / 255, blue: 200 / 255),
      secondary: Color(red: 220 / 255, green: 220 / 255, blue: 220 / 255),
      selected: surfaceColor("#2DD4BF"),
      hover: Color(red: 160 / 255, green: 160 / 255, blue: 160 / 255),
      focus: surfaceColor("#2DD4BF")
    ),
    semantic: SemanticColors(
      success: surfaceColor("#2DD4BF"),
      warning: surfaceColor("#F29B38"),
      error: surfaceColor("#F87171"),
      info: surfaceColor("#2DD4BF")
    )
  )

  let typography = Typography(
    largeTitle: .system(size: 26, weight: .bold),
    title: .system(size: 15, weight: .semibold),
    headline: .system(size: 13, weight: .semibold),
    subheadline: .system(size: 12, weight: .semibold),
    body: .system(size: 13, weight: .regular),
    caption: .system(size: 11, weight: .regular),
    caption2: .system(size: 10.5, weight: .semibold),
    emoji: EmojiTypography(
      small: .system(size: 15),
      medium: .system(size: 20),
      large: .system(size: 28),
      extraLarge: .system(size: 40)
    )
  )

  let spacing = Spacing(
    xs: 4,
    small: 8,
    medium: 16,
    large: 24,
    xl: 32,
    xxl: 48
  )

  let cornerRadius = CornerRadius(
    small: SurfaceStyle.concentricInnerRadius(outerRadius: 20, padding: 14),
    medium: SurfaceStyle.concentricInnerRadius(outerRadius: 20, padding: 10),
    large: 14,
    xl: SurfaceStyle.floating.cornerRadius,
    pill: 999
  )

  let shadows = Shadows(
    small: ShadowStyle(
      color: Color.black.opacity(0.05),
      radius: 2,
      xOffset: 0,
      yOffset: 1
    ),
    medium: ShadowStyle(
      color: Color.black.opacity(0.1),
      radius: 4,
      xOffset: 0,
      yOffset: 2
    ),
    large: ShadowStyle(
      color: Color.black.opacity(0.15),
      radius: 8,
      xOffset: 0,
      yOffset: 4
    )
  )
}
