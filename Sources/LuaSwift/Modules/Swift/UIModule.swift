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
/// This module is NOT included in `installModules()` because it requires
/// UI framework access and a running main run loop. Register it explicitly
/// with ``ModuleRegistry/installUIModule(in:)``.
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
public struct UIModule {

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
  public static func register(in engine: LuaEngine) {
    engine.registerFunction(name: "_luaswift_ui_alert", callback: alertCallback)
    engine.registerFunction(name: "_luaswift_ui_confirm", callback: confirmCallback)

    do {
      try engine.run(
        """
        if not luaswift then luaswift = {} end
        luaswift.ui = {
            alert = _luaswift_ui_alert,
            confirm = _luaswift_ui_confirm
        }
        _luaswift_ui_alert = nil
        _luaswift_ui_confirm = nil
        """)
    } catch {
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
      let semaphore = DispatchSemaphore(value: 0)

      let block = {
        let style: UIAlertController.Style = preferActionSheet ? .actionSheet : .alert
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)

        for (index, button) in buttons.enumerated() {
          let capturedIndex = index + 1
          let actionStyle: UIAlertAction.Style
          switch button.role {
          case .destructive: actionStyle = .destructive
          case .cancel: actionStyle = .cancel
          case .normal: actionStyle = .default
          }

          let action = UIAlertAction(title: button.text, style: actionStyle) { _ in
            result = capturedIndex
            semaphore.signal()
          }
          alert.addAction(action)
        }

        guard
          let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController
        else {
          result = 1
          semaphore.signal()
          return
        }

        var presentingVC = rootVC
        while let presented = presentingVC.presentedViewController {
          presentingVC = presented
        }
        presentingVC.present(alert, animated: true)
      }

      if Thread.isMainThread {
        block()
        semaphore.wait()
      } else {
        DispatchQueue.main.async(execute: block)
        semaphore.wait()
      }

      return result
    }

  #endif
}
