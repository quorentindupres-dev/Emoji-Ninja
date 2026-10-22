import SwiftUI
import ninjalib

struct FastEmojiButton: View {
  let emojiData: EmojibaseEmoji
  let action: () -> Void
  let isSelected: Bool
  let buttonSize: CGFloat
  @Environment(\.theme) private var theme
  @State private var isHovered = false
  @State private var isPressed = false
  @EnvironmentObject var tooltipManager: TooltipManager

  init(
    emojiData: EmojibaseEmoji,
    isSelected: Bool = false,
    buttonSize: CGFloat,
    action: @escaping () -> Void
  ) {
    self.emojiData = emojiData
    self.isSelected = isSelected
    self.buttonSize = buttonSize
    self.action = action
  }

  private var shouldShowEffects: Bool {
    true
  }

  var body: some View {
    GeometryReader { buttonGeometry in
      Text(emojiData.unicode)
        .font(EmojiStyling.emojiFont(size: buttonSize, theme: theme))
        .frame(width: buttonSize, height: buttonSize)
        .background(backgroundView)
        .overlay(overlayView)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .onHover { hovering in
          isHovered = hovering
          if hovering {
            NSCursor.pointingHand.push()
            let buttonFrame = buttonGeometry.frame(in: .named("emojiPicker"))
            tooltipManager.showTooltip(emojiData.label, at: buttonFrame)
          } else {
            NSCursor.pop()
            tooltipManager.hideTooltip()
          }
        }
        .simultaneousGesture(
          DragGesture(minimumDistance: 0)
            .onChanged { _ in
              isPressed = true
            }
            .onEnded { _ in
              isPressed = false
            }
        )
    }
    .frame(width: buttonSize, height: buttonSize)
  }

  private var cellCornerRadius: CGFloat {
    SurfaceStyle.concentricInnerRadius(outerRadius: 20, padding: 10)
  }

  @ViewBuilder
  private var backgroundView: some View {
    RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
      .fill(
        isSelected
          ? theme.colors.surfaceElevated
          : (isHovered ? theme.colors.surface : Color.clear)
      )
  }

  @ViewBuilder
  private var overlayView: some View {
    if isSelected || isHovered {
      RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
        .stroke(borderColor, lineWidth: isSelected ? 1.5 : 1)
    }
  }

  private var borderColor: Color {
    if isSelected {
      return theme.colors.border.selected
    } else if isHovered {
      return theme.colors.border.hover
    } else {
      return Color.clear
    }
  }

}
