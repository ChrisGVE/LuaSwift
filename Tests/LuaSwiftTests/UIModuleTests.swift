//
//  UIModuleTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-04-06.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import LuaSwift

/// Tests for UIModule that can run without a display (argument parsing, registration).
///
/// Dialog presentation tests require a running main run loop and UI framework.
/// Those are marked with skip conditions or documented as manual tests.
final class UIModuleTests: XCTestCase {

  var engine: LuaEngine!

  override func setUp() {
    super.setUp()
    do {
      engine = try LuaEngine()
      ModuleRegistry.installUIModule(in: engine)
    } catch {
      XCTFail("Failed to initialize engine: \(error)")
    }
  }

  override func tearDown() {
    engine = nil
    super.tearDown()
  }

  // MARK: - Registration Tests

  func testModuleRegistered() throws {
    let result = try engine.evaluate("return type(luaswift.ui)")
    XCTAssertEqual(result.stringValue, "table")
  }

  func testAlertFunctionExists() throws {
    let result = try engine.evaluate("return type(luaswift.ui.alert)")
    XCTAssertEqual(result.stringValue, "function")
  }

  func testConfirmFunctionExists() throws {
    let result = try engine.evaluate("return type(luaswift.ui.confirm)")
    XCTAssertEqual(result.stringValue, "function")
  }

  func testGlobalNamespaceClean() throws {
    // Internal callbacks must not leak into global namespace
    let alertGlobal = try engine.evaluate("return _luaswift_ui_alert")
    XCTAssertEqual(alertGlobal, .nil)

    let confirmGlobal = try engine.evaluate("return _luaswift_ui_confirm")
    XCTAssertEqual(confirmGlobal, .nil)
  }

  // MARK: - Argument Validation Tests

  func testAlertRequiresTwoArguments() throws {
    XCTAssertThrowsError(try engine.run("luaswift.ui.alert()")) { error in
      let msg = String(describing: error)
      XCTAssertTrue(
        msg.contains("requires at least title and message"),
        "Expected argument count error, got: \(msg)"
      )
    }
  }

  func testAlertRequiresStringTitle() throws {
    XCTAssertThrowsError(try engine.run("luaswift.ui.alert(42, 'msg')")) { error in
      let msg = String(describing: error)
      XCTAssertTrue(
        msg.contains("title must be a string"),
        "Expected title type error, got: \(msg)"
      )
    }
  }

  func testAlertRequiresStringMessage() throws {
    XCTAssertThrowsError(try engine.run("luaswift.ui.alert('Title', 42)")) { error in
      let msg = String(describing: error)
      XCTAssertTrue(
        msg.contains("message must be a string"),
        "Expected message type error, got: \(msg)"
      )
    }
  }

  func testAlertRejectsEmptyButtonArray() throws {
    XCTAssertThrowsError(try engine.run("luaswift.ui.alert('Title', 'Msg', {})")) { error in
      let msg = String(describing: error)
      XCTAssertTrue(
        msg.contains("must not be empty"),
        "Expected empty-buttons error, got: \(msg)"
      )
    }
  }

  func testAlertRejectsNonArrayButtons() throws {
    XCTAssertThrowsError(try engine.run("luaswift.ui.alert('Title', 'Msg', 'not a table')")) {
      error in
      let msg = String(describing: error)
      XCTAssertTrue(
        msg.contains("buttons must be an array"),
        "Expected buttons-type error, got: \(msg)"
      )
    }
  }

  func testAlertRejectsButtonWithoutTextField() throws {
    XCTAssertThrowsError(
      try engine.run("luaswift.ui.alert('T', 'M', {{role='destructive'}})")
    ) { error in
      let msg = String(describing: error)
      XCTAssertTrue(
        msg.contains("must have a") && msg.contains("text"),
        "Expected missing-text error, got: \(msg)"
      )
    }
  }

  func testAlertRejectsUnknownButtonRole() throws {
    XCTAssertThrowsError(
      try engine.run("luaswift.ui.alert('T', 'M', {{text='OK', role='unknown'}})")
    ) { error in
      let msg = String(describing: error)
      XCTAssertTrue(
        msg.contains("unknown button role"),
        "Expected unknown-role error, got: \(msg)"
      )
    }
  }

  func testAlertRejectsNumericButtonEntry() throws {
    XCTAssertThrowsError(
      try engine.run("luaswift.ui.alert('T', 'M', {42})")
    ) { error in
      let msg = String(describing: error)
      XCTAssertTrue(
        msg.contains("must be a string or table"),
        "Expected button-type error, got: \(msg)"
      )
    }
  }

  func testConfirmRequiresTwoArguments() throws {
    XCTAssertThrowsError(try engine.run("luaswift.ui.confirm('only title')")) { error in
      let msg = String(describing: error)
      XCTAssertTrue(
        msg.contains("requires at least title and message"),
        "Expected argument count error, got: \(msg)"
      )
    }
  }

  // MARK: - InstallUIModule Independence Test

  func testInstallOnFreshEngineDoesNotThrow() throws {
    let freshEngine = try LuaEngine()
    // Must not throw even though no dialog will be shown
    XCTAssertNoThrow(ModuleRegistry.installUIModule(in: freshEngine))

    let result = try freshEngine.evaluate("return type(luaswift.ui)")
    XCTAssertEqual(result.stringValue, "table")
  }

  func testInstallDoesNotAlterOtherModules() throws {
    let freshEngine = try LuaEngine()
    ModuleRegistry.installModules(in: freshEngine)
    ModuleRegistry.installUIModule(in: freshEngine)

    // Core modules still present
    let jsonType = try freshEngine.evaluate("return type(luaswift.json)")
    XCTAssertEqual(jsonType.stringValue, "table")

    let uiType = try freshEngine.evaluate("return type(luaswift.ui)")
    XCTAssertEqual(uiType.stringValue, "table")
  }
}
