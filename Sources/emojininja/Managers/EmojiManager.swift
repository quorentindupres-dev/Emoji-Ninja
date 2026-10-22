import AppKit
import Carbon
@preconcurrency import Combine
import SwiftUI
import ninjalib

final class KeyableFloatingPanel: NSPanel {
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}

@MainActor
class EmojiManager: ObservableObject {
  @Published var isPickerShowing = false
  @Published var selectedSkinTone: SkinTone = .default
  @Published var shouldResetSearch = false

  private var pickerWindow: NSWindow?
  private nonisolated(unsafe) var hotKeyRef: EventHotKeyRef?
  private nonisolated(unsafe) var hotKeyHandlerRef: EventHandlerRef?
  private nonisolated(unsafe) var themeObserver: AnyCancellable?
  private var previousApp: NSRunningApplication?
  private var savedQuartzCursorLocation: CGPoint?
  private var lastScreenFrame: CGRect?

  init() {
    setupHotKey()
    setupThemeObserver()
  }

  func showPicker() {
    if let window = pickerWindow, window.isVisible {
      hidePicker(restoreMouse: true)
      return
    }

    // Store the currently focused app and mouse position before showing picker
    if let frontmost = NSWorkspace.shared.frontmostApplication,
      frontmost.bundleIdentifier != Bundle.main.bundleIdentifier
    {
      previousApp = frontmost
    }
    savedQuartzCursorLocation = CGEvent(source: nil)?.location

    // Get current screen
    let currentScreen = getCurrentScreen()

    // Recreate window if screen changed or doesn't exist
    if pickerWindow == nil || lastScreenFrame != currentScreen.frame {
      if pickerWindow != nil {
        pickerWindow?.close()
        pickerWindow = nil
      }
      createPickerWindow()
      lastScreenFrame = currentScreen.frame
    }

    guard let window = pickerWindow else { return }

    positionWindowAtCursor(window)
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    // Reset search and selection when showing
    shouldResetSearch = true
    isPickerShowing = true
  }

  func hidePicker(restoreMouse: Bool = true) {
    pickerWindow?.orderOut(nil)
    isPickerShowing = false

    if restoreMouse, let savedPoint = savedQuartzCursorLocation {
      CGWarpMouseCursorPosition(savedPoint)
      CGAssociateMouseAndMouseCursorPosition(1)
    }

    if let app = previousApp {
      app.activate(options: [])
    }
  }

  private func createPickerWindow() {
    let currentScreen = getCurrentScreen()
    let windowSize = calculateOptimalWindowSize(for: currentScreen)
    let contentView = EmojiPickerView(
      windowSize: windowSize,
      onEmojiSelected: { [weak self] emojiData in
        self?.handleEmojiSelection(emojiData)
      },
      emojiManager: self
    )
    .themedEnvironment(ThemeManager.shared)

    let window = KeyableFloatingPanel(
      contentRect: NSRect(origin: .zero, size: windowSize),
      styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    window.title = "Emoji Ninja \(BuildVersion.display)"
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isFloatingPanel = true
    window.becomesKeyOnlyIfNeeded = false
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true
    window.sharingType = .readOnly
    window.isMovableByWindowBackground = true
    window.standardWindowButton(.closeButton)?.isHidden = true
    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
    window.standardWindowButton(.zoomButton)?.isHidden = true
    window.contentView = NSHostingView(rootView: contentView)
    window.level = .floating
    window.isReleasedWhenClosed = false
    pickerWindow = window

    setupWindowObservers()
  }

  private func getCurrentScreen() -> NSScreen {
    let mouseLocation = NSEvent.mouseLocation
    let screens = NSScreen.screens
    return screens.first { screen in
      screen.frame.contains(mouseLocation)
    } ?? NSScreen.main ?? screens.first!
  }

  private func calculateOptimalWindowSize(for screen: NSScreen) -> CGSize {
    let pickerWidth = min(max(540, screen.frame.width * 0.32), 620)
    let pickerHeight = min(max(410, pickerWidth * 0.76), 470)
    return CGSize(width: pickerWidth, height: pickerHeight)
  }

  private func positionWindowAtCursor(_ window: NSWindow) {
    let mouseLocation = NSEvent.mouseLocation
    let windowFrame = window.frame
    let currentScreen = getCurrentScreen()

    let newOrigin = CGPoint(
      x: mouseLocation.x - windowFrame.width / 2,
      y: mouseLocation.y - windowFrame.height / 2
    )

    window.setFrameOrigin(
      constrainToScreen(point: newOrigin, windowSize: windowFrame.size, screen: currentScreen)
    )
  }

  private func constrainToScreen(point: CGPoint, windowSize: CGSize, screen: NSScreen) -> CGPoint {

    let screenFrame = screen.visibleFrame
    var constrainedPoint = point

    // Keep window on screen
    if constrainedPoint.x + windowSize.width > screenFrame.maxX {
      constrainedPoint.x = screenFrame.maxX - windowSize.width
    }
    if constrainedPoint.x < screenFrame.minX {
      constrainedPoint.x = screenFrame.minX
    }
    if constrainedPoint.y + windowSize.height > screenFrame.maxY {
      constrainedPoint.y = screenFrame.maxY - windowSize.height
    }
    if constrainedPoint.y < screenFrame.minY {
      constrainedPoint.y = screenFrame.minY
    }

    return constrainedPoint
  }

  private func setupWindowObservers() {
    guard let window = pickerWindow else { return }

    // Close window when it loses focus (because user clicked outside), without warping mouse back
    NotificationCenter.default.addObserver(
      forName: NSWindow.didResignKeyNotification,
      object: window,
      queue: .main
    ) { [weak self] _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
        if let window = self?.pickerWindow, window.isVisible, !window.isKeyWindow {
          self?.hidePicker(restoreMouse: false)
        }
      }
    }
  }

  private func handleEmojiSelection(_ emojiData: EmojibaseEmoji) {
    let emojiWithSkinTone = emojiData.withSkinTone(selectedSkinTone)
    FrequentlyUsedEmojiManager.shared.recordEmojiUsage(emojiWithSkinTone)
    copyToClipboard(emojiWithSkinTone)

    // Hide picker, warp mouse back to saved location, and activate previousApp immediately
    hidePicker(restoreMouse: true)

    // Wait 75ms for previousApp to regain key focus before posting keyDown + keyUp CGEvents
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) {
      self.typeEmojiDirectly(emojiWithSkinTone)
    }

    showBriefFeedback()
  }

  private func typeEmojiDirectly(_ emoji: String) {
    // Check if we have accessibility permissions; prompt once if invalidated after binary update
    if !AXIsProcessTrusted() {
      let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
      _ = AXIsProcessTrustedWithOptions(options)
      print("❌ No accessibility permissions. Copied emoji to clipboard and prompted for Accessibility.")
      return
    }

    self.typeUnicodeDirectly(emoji)
  }

  private func typeUnicodeDirectly(_ emoji: String) {
    guard let source = CGEventSource(stateID: .hidSystemState) else {
      print("❌ Failed to create CGEventSource")
      return
    }

    // Convert emoji to UTF-16 and post both keyDown and keyUp events
    let utf16 = Array(emoji.utf16)

    if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
      let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
    {
      keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
      keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
      keyDown.post(tap: .cgAnnotatedSessionEventTap)
      keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }

    print("⌨️ Typed emoji directly: \(emoji)")
  }

  private func copyToClipboard(_ emoji: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(emoji, forType: .string)
  }

  private func showBriefFeedback() {
    // Simple console feedback - could be enhanced with toast notification
  }

  private func setupHotKey() {
    let eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    let hotKeyID = EventHotKeyID(signature: OSType(fourCharCode("EMNJ")), id: 1)

    let status = InstallEventHandler(
      GetEventDispatcherTarget(),
      { _, event, userData in
        guard let event else { return noErr }
        var receivedHotKeyID = EventHotKeyID()
        let copyStatus = GetEventParameter(
          event,
          EventParamName(kEventParamDirectObject),
          EventParamType(typeEventHotKeyID),
          nil,
          MemoryLayout<EventHotKeyID>.size,
          nil,
          &receivedHotKeyID
        )
        guard copyStatus == noErr, receivedHotKeyID.signature == OSType(fourCharCode("EMNJ")),
          receivedHotKeyID.id == 1
        else {
          return noErr
        }
        // Hardware Right Option check (0x40 = NX_DEVICERALTKEYMASK, 0x20 = NX_DEVICELALTKEYMASK)
        let rawFlags = CGEventSource.flagsState(.combinedSessionState).rawValue
        let leftOptionOnly = (rawFlags & 0x20 != 0) && (rawFlags & 0x40 == 0)
        if leftOptionOnly {
          return noErr
        }
        guard let userData else { return noErr }
        let manager = Unmanaged<EmojiManager>.fromOpaque(userData).takeUnretainedValue()
        Task { @MainActor in
          manager.showPicker()
        }
        return noErr
      },
      1,
      [eventType],
      Unmanaged.passUnretained(self).toOpaque(),
      &hotKeyHandlerRef
    )
    guard status == noErr else {
      print("❌ Failed to install hotkey handler: \(status)")
      return
    }

    let registerStatus = RegisterEventHotKey(
      UInt32(kVK_ANSI_M),
      UInt32(optionKey),
      hotKeyID,
      GetEventDispatcherTarget(),
      0,
      &hotKeyRef
    )
    if registerStatus != noErr {
      print("❌ Failed to register hotkey: \(registerStatus)")
    }
  }

  private func setupThemeObserver() {
    themeObserver = ThemeManager.shared.$currentTheme
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.recreatePickerWindowIfNeeded()
      }
  }

  private func recreatePickerWindowIfNeeded() {
    if pickerWindow != nil {
      pickerWindow?.close()
      pickerWindow = nil
    }
  }

  deinit {
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
    }
    if let hotKeyHandlerRef {
      RemoveEventHandler(hotKeyHandlerRef)
    }
    themeObserver?.cancel()
  }
}

private func fourCharCode(_ string: String) -> FourCharCode {
  string.utf8.reduce(0) { ($0 << 8) + FourCharCode($1) }
}
