import SwiftUI

struct CategoryPill: View {
  let title: String
  let emoji: String
  let isSelected: Bool
  let action: () -> Void
  @Environment(\.theme) private var theme

  var body: some View {
    Button(action: action) {
      HStack(spacing: 5) {
        Text(emoji)
          .font(.system(size: 14))
        if isSelected {
          Text(title)
            .font(theme.typography.caption)
            .lineLimit(1)
        }
      }
    }
    .categoryPillStyle(isSelected: isSelected)
    .help(title)
  }
}
