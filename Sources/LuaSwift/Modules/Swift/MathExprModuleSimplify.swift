//
//  MathExprModuleSimplify.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-04-07.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

#if LUASWIFT_NUMERICSWIFT
  import Foundation
  import NumericSwift

  extension MathExprModule {

    // MARK: - Simplification Helpers

    /// Returns true if the expression is the number zero.
    static func isZero(_ expr: MathExprAST) -> Bool {
      if case .number(let n) = expr { return n == 0 }
      return false
    }

    /// Returns true if the expression is the number one.
    static func isOne(_ expr: MathExprAST) -> Bool {
      if case .number(let n) = expr { return n == 1 }
      return false
    }

    /// Extracts the Double value from a `.number` node, nil otherwise.
    static func numericValue(_ expr: MathExprAST) -> Double? {
      if case .number(let n) = expr { return n }
      return nil
    }

    /// Extracts `(coefficient, variable)` from `a*x`, `x*a`, or plain `x`.
    /// Returns nil if the term doesn't match those patterns.
    static func extractLinearTerm(_ expr: MathExprAST) -> (coeff: Double, variable: MathExprAST)? {
      switch expr {
      case .variable:
        return (1.0, expr)
      case .binary(let op, let left, let right) where op == "*":
        if let c = numericValue(left) {
          return (c, right)
        }
        if let c = numericValue(right) {
          return (c, left)
        }
        return nil
      default:
        return nil
      }
    }

    /// Extracts `(base, exponent)` from `x^n`. Returns nil for non-power nodes.
    static func extractPowerParts(_ expr: MathExprAST) -> (
      base: MathExprAST, exponent: MathExprAST
    )? {
      guard case .binary(let op, let base, let exp) = expr, op == "^" else { return nil }
      return (base, exp)
    }

    // MARK: - Constant Function Folding

    private static func foldConstantCall(name: String, args: [MathExprAST]) -> MathExprAST? {
      guard args.count == 1, let v = numericValue(args[0]) else { return nil }
      let result: Double?
      switch name {
      case "sin": result = sin(v)
      case "cos": result = cos(v)
      case "tan": result = tan(v)
      case "sqrt": result = v >= 0 ? sqrt(v) : nil
      case "exp": result = exp(v)
      case "log", "ln": result = v > 0 ? log(v) : nil
      case "abs": result = abs(v)
      case "floor": result = floor(v)
      case "ceil": result = ceil(v)
      default: return nil
      }
      guard let r = result else { return nil }
      return .number(r)
    }

    // MARK: - Binary Simplification

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private static func simplifyBinary(op: String, left: MathExprAST, right: MathExprAST)
      -> MathExprAST
    {
      // Constant folding
      if let lv = numericValue(left), let rv = numericValue(right) {
        switch op {
        case "+": return .number(lv + rv)
        case "-": return .number(lv - rv)
        case "*": return .number(lv * rv)
        case "/": return rv != 0 ? .number(lv / rv) : .binary(op: op, left: left, right: right)
        case "^": return .number(pow(lv, rv))
        default: break
        }
      }
      switch op {
      case "+":
        if isZero(left) { return right }
        if isZero(right) { return left }
        return simplifyLikeTerms(op: op, left: left, right: right)
      case "-":
        if isZero(right) { return left }
        if left == right { return .number(0) }
        return simplifyLikeTerms(op: op, left: left, right: right)
      case "*":
        if isZero(left) || isZero(right) { return .number(0) }
        if isOne(left) { return right }
        if isOne(right) { return left }
      case "/":
        if isOne(right) { return left }
      case "^":
        if isZero(right) { return .number(1) }
        if isOne(right) { return left }
        if isOne(left) { return .number(1) }
        if isZero(left), let rv = numericValue(right), rv > 0 { return .number(0) }
        return simplifyPowerProduct(op: op, left: left, right: right)
      default: break
      }
      return .binary(op: op, left: left, right: right)
    }

    // MARK: - Like-Terms and Power Rules

    private static func simplifyLikeTerms(op: String, left: MathExprAST, right: MathExprAST)
      -> MathExprAST
    {
      guard let (lc, lv) = extractLinearTerm(left),
        let (rc, rv) = extractLinearTerm(right),
        lv == rv
      else {
        return .binary(op: op, left: left, right: right)
      }
      let combined = op == "+" ? lc + rc : lc - rc
      if combined == 0 { return .number(0) }
      if combined == 1 { return lv }
      return .binary(op: "*", left: .number(combined), right: lv)
    }

    private static func simplifyPowerProduct(op: String, left: MathExprAST, right: MathExprAST)
      -> MathExprAST
    {
      // (x^a)^b -> x^(a*b) when a,b are numeric
      if op == "^",
        let (innerBase, innerExp) = extractPowerParts(left),
        let a = numericValue(innerExp),
        let b = numericValue(right)
      {
        return .binary(op: "^", left: innerBase, right: .number(a * b))
      }
      return .binary(op: op, left: left, right: right)
    }

    // MARK: - Main Simplify Entry Point

    /// Recursively simplify a MathExprAST using algebraic identity rules.
    static func simplify(_ expr: MathExprAST) -> MathExprAST {
      switch expr {
      case .number, .imaginary, .constant, .variable:
        return expr

      case .unary(let op, let operand):
        let s = simplify(operand)
        if op == "-" {
          if isZero(s) { return .number(0) }
          if case .unary(let innerOp, let inner) = s, innerOp == "-" { return inner }
        }
        return .unary(op: op, operand: s)

      case .binary(let op, let left, let right):
        let sl = simplify(left)
        let sr = simplify(right)
        return simplifyBinary(op: op, left: sl, right: sr)

      case .call(let name, let args):
        let sArgs = args.map { simplify($0) }
        return foldConstantCall(name: name, args: sArgs) ?? .call(name: name, args: sArgs)
      }
    }
  }

#endif  // LUASWIFT_NUMERICSWIFT
