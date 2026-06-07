//
//  UIModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-04-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//

import Foundation

#if canImport(AppKit)
  import AppKit
#elseif canImport(UIKit)
  import UIKit
#endif

/// Swift-backed UI module for LuaSwift.
///
/// Provides alert and confirmation dialog support using native platform APIs
/// (NSAlert on macOS, UIAlertController on iOS). Dialogs block the Lua call
/// until the user responds.
///
/// This module is NOT included in `ModuleRegistry.install(in:)` because it requires
/// UI framework access and a running main run loop. Register it explicitly
/// with ``UIModule/install(in:)``.
///
/// ## Lua API
///
/// ```lua
/// local ui = require("luaswift.ui")
///
/// -- Simple alert (single OK button), returns 1
/// local result = ui.alert("Title", "Message")
///
/// -- Alert with custom buttons, returns 1-indexed button number
/// local result = ui.alert("Save?", "Changes will be lost.", {"Save", "Don't Save", "Cancel"})
///
/// -- Alert with button roles
/// local result = ui.alert("Delete?", "This is permanent.", {
///     {text = "Delete", role = "destructive"},
///     {text = "Cancel", role = "cancel"}
/// })
///
/// -- Confirmation dialog (action sheet style on iOS, same as alert on macOS)
/// local result = ui.confirm("Delete?", "This cannot be undone.", {"Delete", "Cancel"})
/// ```
///
/// Button roles:
/// - `"destructive"` — displayed in red/destructive style
/// - `"cancel"` — keyboard cancel action (Escape key on macOS)
///
/// Return value is the 1-indexed position of the button pressed.
public struct UIModule: LuaSwiftModule {

  // MARK: - Internal Types

  /// Parsed button specification from Lua arguments
  private struct ButtonSpec {
    let text: String
    let role: ButtonRole

    enum ButtonRole {
      case normal
      case destructive
      case cancel
    }
  }

  // MARK: - Registration

  /// Register the UI module with a LuaEngine.
  ///
  /// - Parameter engine: The Lua engine to register with
  /// - Throws: An error if the module's Lua setup code fails to run.
  public static func install(in engine: LuaEngine) throws {
    engine.registerFunction(name: "_luaswift_ui_alert", callback: alertCallback)
    engine.registerFunction(name: "_luaswift_ui_confirm", callback: confirmCallback)

    try engine.run(
      """
      if not luaswift then luaswift = {} end
      luaswift.ui = {
          alert = _luaswift_ui_alert,
          confirm = _luaswift_ui_confirm
      }
      _luaswift_ui_alert = nil
      _luaswift_ui_confirm = nil
      package.loaded["luaswift.ui"] = luaswift.ui
      """)
  }

  /// Deprecated alias for ``install(in:)`` that swallows setup failures.
  ///
  /// - Parameter engine: The Lua engine to register with
  @available(*, deprecated, message: "Use install(in:) which surfaces setup failures; register(in:) swallows them.")
  public static func register(in engine: LuaEngine) {
    do { try install(in: engine) } catch {
      #if DEBUG
        print("[LuaSwift] UIModule setup failed: \(error)")
      #endif
    }
  }

  // MARK: - Callbacks

  /// Handle `ui.alert(title, message, buttons?)` Lua calls
  private static func alertCallback(_ args: [LuaValue]) throws -> LuaValue {
    let (title, message, buttons) = try parseDialogArgs(args, funcName: "ui.alert")
    let index = try showAlert(
      title: title, message: message, buttons: buttons, isActionSheet: false)
    return .number(Double(index))
  }

  /// Handle `ui.confirm(title, message, buttons?)` Lua calls
  private static func confirmCallback(_ args: [LuaValue]) throws -> LuaValue {
    let (title, message, buttons) = try parseDialogArgs(args, funcName: "ui.confirm")
    let index = try showAlert(title: title, message: message, buttons: buttons, isActionSheet: true)
    return .number(Double(index))
  }

  // MARK: - Argument Parsing

  /// Parse common dialog arguments: title, message, optional buttons
  private static func parseDialogArgs(
    _ args: [LuaValue],
    funcName: String
  ) throws -> (title: String, message: String, buttons: [ButtonSpec]) {
    guard args.count >= 2 else {
      throw LuaError.callbackError("\(funcName) requires at least title and message arguments")
    }
    guard let title = args[0].stringValue else {
      throw LuaError.callbackError("\(funcName): title must be a string")
    }
    guard let message = args[1].stringValue else {
      throw LuaError.callbackError("\(funcName): message must be a string")
    }

    let buttons: [ButtonSpec]
    if args.count >= 3 {
      buttons = try parseButtons(args[2], funcName: funcName)
    } else {
      buttons = [ButtonSpec(text: "OK", role: .normal)]
    }

    guard !buttons.isEmpty else {
      throw LuaError.callbackError("\(funcName): buttons array must not be empty")
    }

    return (title, message, buttons)
  }

  /// Parse buttons from Lua value — accepts array of strings or array of {text, role} tables
  private static func parseButtons(_ value: LuaValue, funcName: String) throws -> [ButtonSpec] {
    switch value {
    case .array(let arr):
      return try arr.enumerated().map { (index, item) in
        try parseSingleButton(item, index: index + 1, funcName: funcName)
      }
    case .table(let dict):
      if dict.isEmpty {
        return []  // Empty table → empty buttons (caught by caller)
      }
      // Single button as table: {text="...", role="..."}
      let spec = try parseSingleButton(value, index: 1, funcName: funcName)
      return [spec]
    default:
      throw LuaError.callbackError("\(funcName): buttons must be an array")
    }
  }

  /// Parse a single button spec from a Lua value (string or table)
  private static func parseSingleButton(
    _ value: LuaValue,
    index: Int,
    funcName: String
  ) throws -> ButtonSpec {
    switch value {
    case .string(let text):
      return ButtonSpec(text: text, role: .normal)
    case .table(let dict):
      guard let text = dict["text"]?.stringValue else {
        throw LuaError.callbackError(
          "\(funcName): button at index \(index) must have a 'text' field"
        )
      }
      let role: ButtonSpec.ButtonRole
      if let roleStr = dict["role"]?.stringValue {
        switch roleStr.lowercased() {
        case "destructive": role = .destructive
        case "cancel": role = .cancel
        default:
          throw LuaError.callbackError(
            "\(funcName): unknown button role '\(roleStr)'; use 'destructive' or 'cancel'"
          )
        }
      } else {
        role = .normal
      }
      return ButtonSpec(text: text, role: role)
    default:
      throw LuaError.callbackError(
        "\(funcName): button at index \(index) must be a string or table"
      )
    }
  }

  // MARK: - Platform Dialog Presentation

  /// Show a dialog and block until the user dismisses it.
  ///
  /// Returns the 1-indexed position of the pressed button.
  private static func showAlert(
    title: String,
    message: String,
    buttons: [ButtonSpec],
    isActionSheet: Bool
  ) throws -> Int {
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
      return try showNSAlert(title: title, message: message, buttons: buttons)
    #elseif canImport(UIKit)
      return try showUIAlert(
        title: title, message: message, buttons: buttons, preferActionSheet: isActionSheet)
    #else
      throw LuaError.callbackError("UIModule is not supported on this platform")
    #endif
  }

  // MARK: - macOS Implementation

  #if canImport(AppKit) && !targetEnvironment(macCatalyst)

    /// Present an NSAlert and return the 1-indexed button pressed.
    private static func showNSAlert(
      title: String,
      message: String,
      buttons: [ButtonSpec]
    ) throws -> Int {
      var result = 0
      let semaphore = DispatchSemaphore(value: 0)

      let block = {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning

        for button in buttons {
          let btn = alert.addButton(withTitle: button.text)
          if button.role == .destructive {
            if #available(macOS 11.0, *) {
              btn.hasDestructiveAction = true
            }
          }
        }

        let response = alert.runModal()
        // NSAlert returns NSAlertFirstButtonReturn (1000), +1 per button
        let idx = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
        result = idx + 1
        semaphore.signal()
      }

      if Thread.isMainThread {
        block()
      } else {
        DispatchQueue.main.async(execute: block)
        semaphore.wait()
      }

      return result
    }

  #endif

  // MARK: - iOS Implementation

  #if canImport(UIKit) && !os(watchOS)

    /// Present a UIAlertController and return the 1-indexed button pressed.
    private static func showUIAlert(
      title: String,
      message: String,
      buttons: [ButtonSpec],
      preferActionSheet: Bool
    ) throws -> Int {
      var result = 0
      var done = false
      let semaphore = DispatchSemaphore(value: 0)

      // Completion is invoked from UIAlertAction handlers, from the no-presenter
      // fallback, and from the dismissal delegate below. It records the result
      // and unblocks whichever wait strategy is in use: the run-loop spin on the
      // main-thread path or the semaphore on the background-thread path.
      let complete: (Int) -> Void = { index in
        // Idempotent: only the first completion wins. A user-initiated dismissal
        // also fires the dismissal delegate after an action handler has already
        // completed, so the guard makes that second call a no-op.
        guard !done else { return }
        result = index
        done = true
        semaphore.signal()
      }

      // If an action sheet is dismissed without choosing an action (e.g. an iPad
      // popover dismissed by an outside tap) no action handler fires. Map that
      // to the cancel button's 1-indexed position if one exists, otherwise 0
      // ("dismissed without selection"), so the wait always terminates.
      let dismissIndex = buttons.firstIndex { $0.role == .cancel }.map { $0 + 1 } ?? 0

      // Retained for the lifetime of this call so the alert's (weakly held)
      // presentation-controller delegate stays alive until completion.
      var dismissReporter: AlertDismissReporter?

      // Weak handle to the presented alert, used as a fail-safe: the dismissal
      // delegate is not invoked for *programmatic* dismissals (e.g. the
      // presenter being torn down), so the wait loops also watch for the alert
      // leaving the window after it was shown and treat that as a dismissal.
      weak var presentedAlert: UIAlertController?

      let block = {
        let style: UIAlertController.Style = preferActionSheet ? .actionSheet : .alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        presentedAlert = alert

        for (index, button) in buttons.enumerated() {
          let capturedIndex = index + 1
          let actionStyle: UIAlertAction.Style
          switch button.role {
          case .destructive: actionStyle = .destructive
          case .cancel: actionStyle = .cancel
          case .normal: actionStyle = .default
          }

          let action = UIAlertAction(title: button.text, style: actionStyle) { _ in
            complete(capturedIndex)
          }
          alert.addAction(action)
        }

        guard
          let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController
        else {
          complete(1)
          return
        }

        let reporter = AlertDismissReporter { complete(dismissIndex) }
        dismissReporter = reporter

        var presentingVC = rootVC
        while let presented = presentingVC.presentedViewController {
          presentingVC = presented
        }
        presentingVC.present(alert, animated: true)
        // Assign the dismissal delegate after present(): the presentation
        // controller is only guaranteed to exist once presentation has begun,
        // so assigning earlier could silently no-op (notably for iPad
        // popover-backed action sheets) and miss interactive dismissals.
        alert.presentationController?.delegate = reporter
      }

      // Tracks whether the alert was ever actually on screen, so the fail-safe
      // only fires on a real disappearance (not before presentation completes).
      var wasOnScreen = false

      // Watchdog deadline for the pathological case where presentation is
      // requested but the alert never reaches a window at all (e.g. the
      // presenter is already presenting something). Generous so it never trips
      // for a normal presentation animation; only disarmed once the alert is
      // actually shown.
      let presentationDeadline = CFAbsoluteTimeGetCurrent() + 10.0

      // Returns true when the wait should be abandoned without a user action:
      // either the alert was shown and has since left the window (dismissed by
      // a path that ran no handler), or it never appeared before the deadline.
      let shouldAbandonWait: () -> Bool = {
        if presentedAlert?.viewIfLoaded?.window != nil {
          wasOnScreen = true
          return false
        }
        return wasOnScreen || CFAbsoluteTimeGetCurrent() > presentationDeadline
      }

      if Thread.isMainThread {
        // The alert is presented asynchronously and its action handler runs on
        // the main thread. Blocking the main thread on a semaphore would prevent
        // that handler from ever running (deadlock, issue #10). Instead, spin the
        // main run loop so UIKit can present the alert and deliver the tap, until
        // `complete` sets `done`. Single-threaded on the main thread, so reading
        // `done`/`wasOnScreen` here needs no synchronization.
        block()
        while !done {
          CFRunLoopRunInMode(.defaultMode, 0.05, true)
          if shouldAbandonWait() {
            complete(dismissIndex)
          }
        }
      } else {
        DispatchQueue.main.async(execute: block)
        // Wait in short slices so the main thread can be polled for a
        // programmatic dismissal that bypassed both the action handlers and the
        // dismissal delegate. The semaphore signal ends the loop normally.
        while semaphore.wait(timeout: .now() + 0.1) == .timedOut {
          DispatchQueue.main.sync {
            if shouldAbandonWait() {
              complete(dismissIndex)
            }
          }
        }
      }

      // Keep the dismissal delegate alive for the whole wait (the presentation
      // controller holds it weakly).
      withExtendedLifetime(dismissReporter) {}
      return result
    }

    /// Reports an interactive dismissal of the alert/action sheet (one not
    /// triggered by tapping an action), so the blocking call can terminate.
    private final class AlertDismissReporter: NSObject, UIAdaptivePresentationControllerDelegate {
      private let onDismiss: () -> Void

      init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
      }

      func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss()
      }
    }

  #endif
}
