import SwiftUI
import ninjalib

struct EmojiPickerView: View {
  let windowSize: CGSize
  let onEmojiSelected: (EmojibaseEmoji) -> Void
  @ObservedObject var emojiManager: EmojiManager
  @StateObject private var viewModel: EmojiPickerViewModel
  @StateObject private var tooltipManager = TooltipManager()
  @Environment(\.theme) private var theme

  init(
    windowSize: CGSize, onEmojiSelected: @escaping (EmojibaseEmoji) -> Void,
    emojiManager: EmojiManager
  ) {
    self.windowSize = windowSize
    self.onEmojiSelected = onEmojiSelected
    self.emojiManager = emojiManager
    self._viewModel = StateObject(
      wrappedValue: EmojiPickerViewModel(emojiManager: emojiManager))
  }

  var body: some View {
    let searchSnapshot = viewModel.searchDisplaySnapshot
    let isInSearchMode = !searchSnapshot.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

    GeometryReader { geometry in
      ZStack {
        VStack(spacing: 0) {
          // Search Bar
          SearchBar(
            searchText: Binding(
              get: { viewModel.searchText },
              set: { viewModel.setSearchText($0) }
            ),
            emojiManager: emojiManager,
            onKeyPress: viewModel.handleKeyPress,
            onSubmit: handleSubmit,
            onEscape: { emojiManager.hidePicker() }
          )

          // Category Filter Pills
          if !isInSearchMode {
            CategoryFilterView(selectedCategory: $viewModel.selectedCategory)
          }

          Divider()

          // Emoji Content
          ScrollViewReader { proxy in
            ScrollView {
              LazyVStack(alignment: .leading, spacing: 4) {
                Color.clear
                  .frame(height: 1)
                  .id("emoji_content_top")
                if !isInSearchMode {
                  // Category browsing mode
                  EmojiGridView(
                    geometry: geometry,
                    selectedEmojiIndex: viewModel.selectedEmojiIndex,
                    selectedCategory: viewModel.selectedCategory,
                    onEmojiSelected: onEmojiSelected,
                    emojiManager: emojiManager,
                    viewModel: viewModel
                  )
                } else {
                  // Search results mode
                  SearchResultsView(
                    buttonSize: EmojiLayout.cachedButtonSize(
                      for: geometry, theme: theme),
                    searchResults: searchSnapshot.results,
                    selectedEmojiIndex: viewModel.selectedEmojiIndex,
                    onEmojiSelected: onEmojiSelected
                  )
                }
              }
              .padding(.horizontal, theme.spacing.medium)
              .padding(.vertical, theme.spacing.xs)
            }
            .onChange(of: viewModel.selectedEmojiIndex) { _, _ in
              guard viewModel.shouldAutoScrollSelection else { return }
              if let targetId = viewModel.currentScrollTargetId() {
                DispatchQueue.main.async {
                  proxy.scrollTo(targetId, anchor: .center)
                }
              }
              viewModel.consumeAutoScrollSelection()
            }
              .onChange(of: viewModel.selectedCategory) { _, _ in
                proxy.scrollTo("emoji_content_top", anchor: .top)
                viewModel.onSelectedCategoryChangedFromUI()
              }
            }

            Divider()
              .overlay(theme.colors.border.secondary)

            // Raycast-style Multi-Keyword Meaning Footer Bar
            EmojiFooterBar(emoji: viewModel.getCurrentEmoji())
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .fill(theme.colors.background)
          )
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .stroke(theme.colors.border.primary, lineWidth: 1)
          )
          .coordinateSpace(name: "emojiPicker")
          .environmentObject(tooltipManager)

          // Global tooltip overlay
          GlobalTooltipView(tooltipManager: tooltipManager)
        }
      }
      .frame(width: windowSize.width, height: windowSize.height)
      .onKeyPress { keyPress in
        // Handle tab navigation using actual characters
        let character = keyPress.key.character

        if character == "\u{19}" || character == "\u{9}" {  // Tab or Shift+Tab
          if !viewModel.isInSearchMode {
            if character == "\u{19}" {  // Shift+Tab
              viewModel.navigateToPreviousCategory()
            } else if character == "\u{9}" {  // Tab
              viewModel.navigateToNextCategory()
            }
          }
          // Always handle tab events to prevent focus changes
          return .handled
        }
        return .ignored
      }
      .onAppear {
        viewModel.resetSearch()
      }
      .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
        viewModel.resetSearch()
      }
    }

    // MARK: - Helper Functions

    private func handleSubmit() {
      if let selectedEmojiData = viewModel.selectCurrentEmojiData() {
        onEmojiSelected(selectedEmojiData)
      }
    }
  }

  struct EmojiFooterBar: View {
    let emoji: EmojibaseEmoji?
    @Environment(\.theme) private var theme

    var body: some View {
      HStack(spacing: 8) {
        if let emoji {
          Text(emoji.unicode)
            .font(.system(size: 16))
          Text(emoji.label)
            .font(theme.typography.caption)
            .foregroundColor(theme.colors.text.primary)
            .lineLimit(1)

          if let tags = emoji.tags, !tags.isEmpty {
            Text("·")
              .font(theme.typography.caption)
              .foregroundColor(theme.colors.text.tertiary)

            HStack(spacing: 4) {
              ForEach(Array(tags.prefix(5)), id: \.self) { tag in
                Text(tag)
                  .font(theme.typography.caption2)
                  .foregroundColor(theme.colors.text.secondary)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 2)
                  .background(
                    RoundedRectangle(cornerRadius: 4)
                      .fill(theme.colors.surfaceElevated)
                  )
              }
            }
            .lineLimit(1)
          }
        } else {
          Text("Emoji Ninja")
            .font(theme.typography.caption)
            .foregroundColor(theme.colors.text.secondary)
        }

        Spacer(minLength: 4)

        HStack(spacing: 6) {
          Text("↵ Insert")
          Text("·")
          Text("⇥ Tab")
          Text("·")
          Text("⌥M")
        }
        .font(theme.typography.caption2)
        .foregroundColor(theme.colors.text.tertiary)
      }
      .padding(.horizontal, 14)
      .frame(height: 34)
      .background(theme.colors.surface.opacity(0.6))
    }
  }
