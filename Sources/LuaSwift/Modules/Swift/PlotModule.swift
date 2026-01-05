//
//  PlotModule.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-05.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation
import CoreGraphics
import CoreText
#if canImport(ImageIO)
import ImageIO
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Plot module for LuaSwift - matplotlib/seaborn-compatible visualization.
///
/// Uses retained vector graphics architecture where DrawingContext holds scale-free
/// vector commands in memory, enabling the Swift host app to render at any resolution.
///
/// ## Usage
///
/// ```lua
/// local plt = require("luaswift.plot")
///
/// local fig, ax = plt.subplots()
/// ax:plot({1, 2, 3, 4}, {1, 4, 2, 3}, {color='blue', linestyle='--'})
/// ax:set_title("My Plot")
/// ax:set_xlabel("X")
/// ax:set_ylabel("Y")
///
/// -- Export to file
/// fig:savefig("plot.png", {dpi=150})
/// fig:savefig("plot.svg")
/// fig:savefig("plot.pdf")
///
/// -- Or get DrawingContext for host app rendering
/// local ctx = fig:get_context()
/// ```
public struct PlotModule {

    // MARK: - Public Types

    /// A color representation for plotting.
    public struct Color: Equatable {
        public let red: Double
        public let green: Double
        public let blue: Double
        public let alpha: Double

        public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }

        /// Create color from hex string (e.g., "#FF0000" or "FF0000")
        public init?(hex: String) {
            var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

            var rgb: UInt64 = 0
            guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

            if hexSanitized.count == 6 {
                self.red = Double((rgb & 0xFF0000) >> 16) / 255.0
                self.green = Double((rgb & 0x00FF00) >> 8) / 255.0
                self.blue = Double(rgb & 0x0000FF) / 255.0
                self.alpha = 1.0
            } else if hexSanitized.count == 8 {
                self.red = Double((rgb & 0xFF000000) >> 24) / 255.0
                self.green = Double((rgb & 0x00FF0000) >> 16) / 255.0
                self.blue = Double((rgb & 0x0000FF00) >> 8) / 255.0
                self.alpha = Double(rgb & 0x000000FF) / 255.0
            } else {
                return nil
            }
        }

        /// Create color from name
        public init?(name: String) {
            switch name.lowercased() {
            case "black": self = .black
            case "white": self = .white
            case "red": self = .red
            case "green": self = .green
            case "blue": self = .blue
            case "yellow": self = .yellow
            case "cyan": self = .cyan
            case "magenta": self = .magenta
            case "orange": self = .orange
            case "purple": self = .purple
            case "brown": self = .brown
            case "pink": self = .pink
            case "gray", "grey": self = .gray
            case "lightgray", "lightgrey": self = .lightGray
            case "darkgray", "darkgrey": self = .darkGray
            case "none", "transparent": self = .clear
            default: return nil
            }
        }

        public var cgColor: CGColor {
            CGColor(red: red, green: green, blue: blue, alpha: alpha)
        }

        public func toHex(includeAlpha: Bool = false) -> String {
            let r = Int(red * 255)
            let g = Int(green * 255)
            let b = Int(blue * 255)
            if includeAlpha {
                let a = Int(alpha * 255)
                return String(format: "#%02X%02X%02X%02X", r, g, b, a)
            }
            return String(format: "#%02X%02X%02X", r, g, b)
        }

        // Predefined colors
        public static let black = Color(red: 0, green: 0, blue: 0)
        public static let white = Color(red: 1, green: 1, blue: 1)
        public static let red = Color(red: 1, green: 0, blue: 0)
        public static let green = Color(red: 0, green: 0.5, blue: 0)
        public static let blue = Color(red: 0, green: 0, blue: 1)
        public static let yellow = Color(red: 1, green: 1, blue: 0)
        public static let cyan = Color(red: 0, green: 1, blue: 1)
        public static let magenta = Color(red: 1, green: 0, blue: 1)
        public static let orange = Color(red: 1, green: 0.647, blue: 0)
        public static let purple = Color(red: 0.5, green: 0, blue: 0.5)
        public static let brown = Color(red: 0.647, green: 0.165, blue: 0.165)
        public static let pink = Color(red: 1, green: 0.753, blue: 0.796)
        public static let gray = Color(red: 0.5, green: 0.5, blue: 0.5)
        public static let lightGray = Color(red: 0.75, green: 0.75, blue: 0.75)
        public static let darkGray = Color(red: 0.25, green: 0.25, blue: 0.25)
        public static let clear = Color(red: 0, green: 0, blue: 0, alpha: 0)
    }

    /// Text styling for rendering
    public struct TextStyle: Equatable {
        public var fontFamily: String
        public var fontSize: Double
        public var fontWeight: FontWeight
        public var color: Color
        public var anchor: TextAnchor

        public enum FontWeight: String {
            case normal = "normal"
            case bold = "bold"
            case light = "light"
        }

        public enum TextAnchor: String {
            case start = "start"
            case middle = "middle"
            case end = "end"
        }

        public init(
            fontFamily: String = "sans-serif",
            fontSize: Double = 12,
            fontWeight: FontWeight = .normal,
            color: Color = .black,
            anchor: TextAnchor = .start
        ) {
            self.fontFamily = fontFamily
            self.fontSize = fontSize
            self.fontWeight = fontWeight
            self.color = color
            self.anchor = anchor
        }
    }

    /// Line style for strokes
    public enum LineStyle: String {
        case solid = "-"
        case dashed = "--"
        case dotted = ":"
        case dashDot = "-."
        case none = ""

        public var dashPattern: [CGFloat]? {
            switch self {
            case .solid, .none: return nil
            case .dashed: return [6, 4]
            case .dotted: return [2, 2]
            case .dashDot: return [6, 2, 2, 2]
            }
        }
    }

    /// Marker style for scatter points
    public enum MarkerStyle: String {
        case circle = "o"
        case square = "s"
        case diamond = "D"
        case triangleUp = "^"
        case triangleDown = "v"
        case triangleLeft = "<"
        case triangleRight = ">"
        case plus = "+"
        case cross = "x"
        case star = "*"
        case dot = "."
        case none = ""
    }

    /// Drawing command representing a single vector graphics operation
    public enum DrawingCommand: Equatable {
        // Path construction
        case moveTo(x: Double, y: Double)
        case lineTo(x: Double, y: Double)
        case curveTo(cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double)
        case quadCurveTo(cpx: Double, cpy: Double, x: Double, y: Double)
        case closePath

        // Shapes
        case rect(x: Double, y: Double, width: Double, height: Double)
        case ellipse(cx: Double, cy: Double, rx: Double, ry: Double)
        case arc(cx: Double, cy: Double, r: Double, startAngle: Double, endAngle: Double, clockwise: Bool)

        // Text
        case text(String, x: Double, y: Double, style: TextStyle)

        // Transform stack
        case pushTransform(CGAffineTransform)
        case popTransform

        // Style state
        case setStrokeColor(Color)
        case setStrokeWidth(Double)
        case setStrokeStyle(LineStyle)
        case setFillColor(Color)
        case setAlpha(Double)

        // Drawing operations
        case strokePath
        case fillPath
        case fillAndStrokePath

        // Clipping
        case clipRect(x: Double, y: Double, width: Double, height: Double)
        case resetClip

        // Save/restore graphics state
        case saveState
        case restoreState
    }

    /// DrawingContext holds retained vector commands for scale-free rendering
    public final class DrawingContext {
        /// All drawing commands stored in order
        public private(set) var commands: [DrawingCommand] = []

        /// Transform stack for nested coordinate systems
        private var transformStack: [CGAffineTransform] = [.identity]

        /// Current transform (top of stack)
        public var currentTransform: CGAffineTransform {
            transformStack.last ?? .identity
        }

        /// Computed bounds from all drawing commands
        public var bounds: CGRect {
            var minX = Double.infinity
            var minY = Double.infinity
            var maxX = -Double.infinity
            var maxY = -Double.infinity

            for command in commands {
                switch command {
                case .moveTo(let x, let y), .lineTo(let x, let y):
                    minX = Swift.min(minX, x)
                    minY = Swift.min(minY, y)
                    maxX = Swift.max(maxX, x)
                    maxY = Swift.max(maxY, y)
                case .rect(let x, let y, let w, let h):
                    minX = Swift.min(minX, x)
                    minY = Swift.min(minY, y)
                    maxX = Swift.max(maxX, x + w)
                    maxY = Swift.max(maxY, y + h)
                case .ellipse(let cx, let cy, let rx, let ry):
                    minX = Swift.min(minX, cx - rx)
                    minY = Swift.min(minY, cy - ry)
                    maxX = Swift.max(maxX, cx + rx)
                    maxY = Swift.max(maxY, cy + ry)
                case .text(_, let x, let y, _):
                    minX = Swift.min(minX, x)
                    minY = Swift.min(minY, y)
                    maxX = Swift.max(maxX, x)
                    maxY = Swift.max(maxY, y)
                default:
                    break
                }
            }

            if minX == Double.infinity {
                return .zero
            }
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }

        public init() {}

        /// Clear all commands
        public func clear() {
            commands.removeAll()
            transformStack = [.identity]
        }

        /// Number of commands
        public var commandCount: Int {
            commands.count
        }

        // MARK: - Path Construction

        public func moveTo(_ x: Double, _ y: Double) {
            commands.append(.moveTo(x: x, y: y))
        }

        public func lineTo(_ x: Double, _ y: Double) {
            commands.append(.lineTo(x: x, y: y))
        }

        public func curveTo(cp1x: Double, cp1y: Double, cp2x: Double, cp2y: Double, x: Double, y: Double) {
            commands.append(.curveTo(cp1x: cp1x, cp1y: cp1y, cp2x: cp2x, cp2y: cp2y, x: x, y: y))
        }

        public func quadCurveTo(cpx: Double, cpy: Double, x: Double, y: Double) {
            commands.append(.quadCurveTo(cpx: cpx, cpy: cpy, x: x, y: y))
        }

        public func closePath() {
            commands.append(.closePath)
        }

        // MARK: - Shapes

        public func rect(_ x: Double, _ y: Double, _ width: Double, _ height: Double) {
            commands.append(.rect(x: x, y: y, width: width, height: height))
        }

        public func ellipse(cx: Double, cy: Double, rx: Double, ry: Double) {
            commands.append(.ellipse(cx: cx, cy: cy, rx: rx, ry: ry))
        }

        public func circle(cx: Double, cy: Double, r: Double) {
            ellipse(cx: cx, cy: cy, rx: r, ry: r)
        }

        public func arc(cx: Double, cy: Double, r: Double, startAngle: Double, endAngle: Double, clockwise: Bool = false) {
            commands.append(.arc(cx: cx, cy: cy, r: r, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise))
        }

        // MARK: - Text

        public func text(_ string: String, x: Double, y: Double, style: TextStyle = TextStyle()) {
            commands.append(.text(string, x: x, y: y, style: style))
        }

        // MARK: - Transform Stack

        public func pushTransform(_ transform: CGAffineTransform) {
            let combined = currentTransform.concatenating(transform)
            transformStack.append(combined)
            commands.append(.pushTransform(transform))
        }

        public func popTransform() {
            if transformStack.count > 1 {
                transformStack.removeLast()
            }
            commands.append(.popTransform)
        }

        public func translate(_ tx: Double, _ ty: Double) {
            pushTransform(CGAffineTransform(translationX: tx, y: ty))
        }

        public func scale(_ sx: Double, _ sy: Double) {
            pushTransform(CGAffineTransform(scaleX: sx, y: sy))
        }

        public func rotate(_ angle: Double) {
            pushTransform(CGAffineTransform(rotationAngle: angle))
        }

        // MARK: - Style State

        public func setStrokeColor(_ color: Color) {
            commands.append(.setStrokeColor(color))
        }

        public func setStrokeWidth(_ width: Double) {
            commands.append(.setStrokeWidth(width))
        }

        public func setStrokeStyle(_ style: LineStyle) {
            commands.append(.setStrokeStyle(style))
        }

        public func setFillColor(_ color: Color) {
            commands.append(.setFillColor(color))
        }

        public func setAlpha(_ alpha: Double) {
            commands.append(.setAlpha(alpha))
        }

        // MARK: - Drawing Operations

        public func strokePath() {
            commands.append(.strokePath)
        }

        public func fillPath() {
            commands.append(.fillPath)
        }

        public func fillAndStrokePath() {
            commands.append(.fillAndStrokePath)
        }

        // MARK: - State Management

        public func saveState() {
            commands.append(.saveState)
        }

        public func restoreState() {
            commands.append(.restoreState)
        }

        // MARK: - Clipping

        public func clipRect(_ x: Double, _ y: Double, _ width: Double, _ height: Double) {
            commands.append(.clipRect(x: x, y: y, width: width, height: height))
        }

        public func resetClip() {
            commands.append(.resetClip)
        }

        // MARK: - Rendering

        /// Render all commands to a Core Graphics context
        public func render(to context: CGContext, size: CGSize) {
            context.saveGState()

            // Set up coordinate system (origin at bottom-left, y-up for math plots)
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1, y: -1)

            var transformStack: [CGAffineTransform] = [.identity]

            for command in commands {
                switch command {
                case .moveTo(let x, let y):
                    context.move(to: CGPoint(x: x, y: y))

                case .lineTo(let x, let y):
                    context.addLine(to: CGPoint(x: x, y: y))

                case .curveTo(let cp1x, let cp1y, let cp2x, let cp2y, let x, let y):
                    context.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: cp1x, y: cp1y),
                        control2: CGPoint(x: cp2x, y: cp2y)
                    )

                case .quadCurveTo(let cpx, let cpy, let x, let y):
                    context.addQuadCurve(
                        to: CGPoint(x: x, y: y),
                        control: CGPoint(x: cpx, y: cpy)
                    )

                case .closePath:
                    context.closePath()

                case .rect(let x, let y, let w, let h):
                    context.addRect(CGRect(x: x, y: y, width: w, height: h))

                case .ellipse(let cx, let cy, let rx, let ry):
                    context.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))

                case .arc(let cx, let cy, let r, let startAngle, let endAngle, let clockwise):
                    context.addArc(
                        center: CGPoint(x: cx, y: cy),
                        radius: r,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: clockwise
                    )

                case .text(let str, let x, let y, let style):
                    renderText(str, at: CGPoint(x: x, y: y), style: style, context: context, size: size)

                case .pushTransform(let transform):
                    let combined = (transformStack.last ?? .identity).concatenating(transform)
                    transformStack.append(combined)
                    context.saveGState()
                    context.concatenate(transform)

                case .popTransform:
                    if transformStack.count > 1 {
                        transformStack.removeLast()
                    }
                    context.restoreGState()

                case .setStrokeColor(let color):
                    context.setStrokeColor(color.cgColor)

                case .setStrokeWidth(let width):
                    context.setLineWidth(width)

                case .setStrokeStyle(let style):
                    if let pattern = style.dashPattern {
                        context.setLineDash(phase: 0, lengths: pattern)
                    } else {
                        context.setLineDash(phase: 0, lengths: [])
                    }

                case .setFillColor(let color):
                    context.setFillColor(color.cgColor)

                case .setAlpha(let alpha):
                    context.setAlpha(alpha)

                case .strokePath:
                    context.strokePath()

                case .fillPath:
                    context.fillPath()

                case .fillAndStrokePath:
                    context.drawPath(using: .fillStroke)

                case .clipRect(let x, let y, let w, let h):
                    context.clip(to: CGRect(x: x, y: y, width: w, height: h))

                case .resetClip:
                    context.resetClip()

                case .saveState:
                    context.saveGState()

                case .restoreState:
                    context.restoreGState()
                }
            }

            context.restoreGState()
        }

        /// Render text with proper font handling using CoreText
        private func renderText(_ string: String, at point: CGPoint, style: TextStyle, context: CGContext, size: CGSize) {
            context.saveGState()

            // Flip for text (text renders upside-down in flipped context)
            context.translateBy(x: point.x, y: point.y)
            context.scaleBy(x: 1, y: -1)

            // Create font using CoreText
            let font = makeCTFont(style: style)

            // Create attributed string with CoreText attributes
            let attributes: [CFString: Any] = [
                kCTFontAttributeName: font,
                kCTForegroundColorAttributeName: style.color.cgColor
            ]

            let attrString = CFAttributedStringCreate(
                nil,
                string as CFString,
                attributes as CFDictionary
            )!

            let line = CTLineCreateWithAttributedString(attrString)
            let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

            // Adjust x position based on anchor
            var xOffset: CGFloat = 0
            switch style.anchor {
            case .middle:
                xOffset = -bounds.width / 2
            case .end:
                xOffset = -bounds.width
            case .start:
                xOffset = 0
            }

            context.textPosition = CGPoint(x: xOffset, y: -bounds.height / 4)
            CTLineDraw(line, context)

            context.restoreGState()
        }

        /// Create a CTFont with the specified style
        private func makeCTFont(style: TextStyle) -> CTFont {
            var traits: CTFontSymbolicTraits = []
            switch style.fontWeight {
            case .bold:
                traits.insert(.boldTrait)
            case .light:
                // Light weight not directly supported via traits, use system font
                break
            case .normal:
                break
            }

            // Create system font
            #if os(macOS)
            let systemFont = CTFontCreateUIFontForLanguage(.system, style.fontSize, nil) ?? CTFontCreateWithName("Helvetica" as CFString, style.fontSize, nil)
            #else
            let systemFont = CTFontCreateWithName("Helvetica" as CFString, style.fontSize, nil)
            #endif

            // Apply traits if needed
            if !traits.isEmpty {
                if let descriptor = CTFontCopyFontDescriptor(systemFont) as CTFontDescriptor?,
                   let styledDescriptor = CTFontDescriptorCreateCopyWithSymbolicTraits(descriptor, traits, traits) {
                    return CTFontCreateWithFontDescriptor(styledDescriptor, style.fontSize, nil)
                }
            }

            return systemFont
        }

        // MARK: - Export to Image

        #if canImport(ImageIO)
        /// Render to PNG data
        public func renderToPNG(size: CGSize, scale: CGFloat = 1.0) -> Data? {
            let width = Int(size.width * scale)
            let height = Int(size.height * scale)

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else { return nil }

            // Fill with white background
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))

            // Scale for DPI
            context.scaleBy(x: scale, y: scale)

            // Render commands
            render(to: context, size: size)

            guard let image = context.makeImage() else { return nil }

            // Encode to PNG
            let data = NSMutableData()
            #if canImport(UniformTypeIdentifiers)
            guard let dest = CGImageDestinationCreateWithData(
                data as CFMutableData,
                UTType.png.identifier as CFString,
                1, nil
            ) else { return nil }
            #else
            guard let dest = CGImageDestinationCreateWithData(
                data as CFMutableData,
                kUTTypePNG,
                1, nil
            ) else { return nil }
            #endif

            CGImageDestinationAddImage(dest, image, nil)
            guard CGImageDestinationFinalize(dest) else { return nil }

            return data as Data
        }

        /// Render to PDF data
        public func renderToPDF(size: CGSize) -> Data? {
            let data = NSMutableData()

            var mediaBox = CGRect(origin: .zero, size: size)

            guard let consumer = CGDataConsumer(data: data as CFMutableData),
                  let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
            else { return nil }

            context.beginPDFPage(nil)
            render(to: context, size: size)
            context.endPDFPage()
            context.closePDF()

            return data as Data
        }
        #endif

        // MARK: - Export to SVG

        /// Render to SVG string
        public func renderToSVG(size: CGSize) -> String {
            var svg = """
            <?xml version="1.0" encoding="UTF-8"?>
            <svg width="\(Int(size.width))" height="\(Int(size.height))" xmlns="http://www.w3.org/2000/svg">
            <rect width="100%" height="100%" fill="white"/>

            """

            var currentPath = ""
            var strokeColor = Color.black
            var fillColor = Color.clear
            var strokeWidth = 1.0
            var strokeStyle = LineStyle.solid

            func flushPath() {
                if !currentPath.isEmpty {
                    var attrs = "d=\"\(currentPath)\""

                    if fillColor != .clear {
                        attrs += " fill=\"\(fillColor.toHex())\""
                        if fillColor.alpha < 1 {
                            attrs += " fill-opacity=\"\(fillColor.alpha)\""
                        }
                    } else {
                        attrs += " fill=\"none\""
                    }

                    attrs += " stroke=\"\(strokeColor.toHex())\""
                    if strokeColor.alpha < 1 {
                        attrs += " stroke-opacity=\"\(strokeColor.alpha)\""
                    }
                    attrs += " stroke-width=\"\(strokeWidth)\""

                    if let pattern = strokeStyle.dashPattern {
                        attrs += " stroke-dasharray=\"\(pattern.map { "\($0)" }.joined(separator: ","))\""
                    }

                    svg += "<path \(attrs)/>\n"
                    currentPath = ""
                }
            }

            for command in commands {
                switch command {
                case .moveTo(let x, let y):
                    currentPath += "M\(x),\(size.height - y) "

                case .lineTo(let x, let y):
                    currentPath += "L\(x),\(size.height - y) "

                case .curveTo(let cp1x, let cp1y, let cp2x, let cp2y, let x, let y):
                    currentPath += "C\(cp1x),\(size.height - cp1y) \(cp2x),\(size.height - cp2y) \(x),\(size.height - y) "

                case .quadCurveTo(let cpx, let cpy, let x, let y):
                    currentPath += "Q\(cpx),\(size.height - cpy) \(x),\(size.height - y) "

                case .closePath:
                    currentPath += "Z "

                case .rect(let x, let y, let w, let h):
                    flushPath()
                    let fillAttr = fillColor != .clear ? "fill=\"\(fillColor.toHex())\"" : "fill=\"none\""
                    let strokeAttr = "stroke=\"\(strokeColor.toHex())\" stroke-width=\"\(strokeWidth)\""
                    svg += "<rect x=\"\(x)\" y=\"\(size.height - y - h)\" width=\"\(w)\" height=\"\(h)\" \(fillAttr) \(strokeAttr)/>\n"

                case .ellipse(let cx, let cy, let rx, let ry):
                    flushPath()
                    let fillAttr = fillColor != .clear ? "fill=\"\(fillColor.toHex())\"" : "fill=\"none\""
                    let strokeAttr = "stroke=\"\(strokeColor.toHex())\" stroke-width=\"\(strokeWidth)\""
                    svg += "<ellipse cx=\"\(cx)\" cy=\"\(size.height - cy)\" rx=\"\(rx)\" ry=\"\(ry)\" \(fillAttr) \(strokeAttr)/>\n"

                case .arc:
                    // Convert arc to path - simplified, would need proper implementation
                    break

                case .text(let str, let x, let y, let style):
                    flushPath()
                    let escaped = escapeXML(str)
                    let anchor = style.anchor.rawValue
                    let fontWeight = style.fontWeight == .bold ? "font-weight=\"bold\"" : ""
                    svg += "<text x=\"\(x)\" y=\"\(size.height - y)\" font-size=\"\(style.fontSize)\" \(fontWeight) text-anchor=\"\(anchor)\" fill=\"\(style.color.toHex())\">\(escaped)</text>\n"

                case .setStrokeColor(let color):
                    flushPath()
                    strokeColor = color

                case .setStrokeWidth(let width):
                    flushPath()
                    strokeWidth = width

                case .setStrokeStyle(let style):
                    flushPath()
                    strokeStyle = style

                case .setFillColor(let color):
                    flushPath()
                    fillColor = color

                case .strokePath, .fillPath, .fillAndStrokePath:
                    flushPath()

                default:
                    break
                }
            }

            flushPath()

            svg += "</svg>"
            return svg
        }

        private func escapeXML(_ text: String) -> String {
            var result = text
            result = result.replacingOccurrences(of: "&", with: "&amp;")
            result = result.replacingOccurrences(of: "<", with: "&lt;")
            result = result.replacingOccurrences(of: ">", with: "&gt;")
            result = result.replacingOccurrences(of: "\"", with: "&quot;")
            result = result.replacingOccurrences(of: "'", with: "&apos;")
            return result
        }
    }

    // MARK: - Context Storage

    /// Thread-safe storage for DrawingContext instances referenced by Lua
    private static var contexts: [Int: DrawingContext] = [:]
    private static var nextContextId = 1
    private static let contextLock = NSLock()

    /// Store a context and return its ID
    static func storeContext(_ context: DrawingContext) -> Int {
        contextLock.lock()
        defer { contextLock.unlock() }
        let id = nextContextId
        nextContextId += 1
        contexts[id] = context
        return id
    }

    /// Retrieve a context by ID
    static func getContext(_ id: Int) -> DrawingContext? {
        contextLock.lock()
        defer { contextLock.unlock() }
        return contexts[id]
    }

    /// Remove a context by ID
    static func removeContext(_ id: Int) {
        contextLock.lock()
        defer { contextLock.unlock() }
        contexts.removeValue(forKey: id)
    }

    // MARK: - Registration

    /// Register the plot module with a LuaEngine
    public static func register(in engine: LuaEngine) {
        // Context creation
        engine.registerFunction(name: "_luaswift_plot_create_context", callback: createContextCallback)
        engine.registerFunction(name: "_luaswift_plot_destroy_context", callback: destroyContextCallback)
        engine.registerFunction(name: "_luaswift_plot_clear_context", callback: clearContextCallback)
        engine.registerFunction(name: "_luaswift_plot_command_count", callback: commandCountCallback)

        // Path operations
        engine.registerFunction(name: "_luaswift_plot_move_to", callback: moveToCallback)
        engine.registerFunction(name: "_luaswift_plot_line_to", callback: lineToCallback)
        engine.registerFunction(name: "_luaswift_plot_curve_to", callback: curveToCallback)
        engine.registerFunction(name: "_luaswift_plot_close_path", callback: closePathCallback)

        // Shapes
        engine.registerFunction(name: "_luaswift_plot_rect", callback: rectCallback)
        engine.registerFunction(name: "_luaswift_plot_ellipse", callback: ellipseCallback)
        engine.registerFunction(name: "_luaswift_plot_circle", callback: circleCallback)

        // Text
        engine.registerFunction(name: "_luaswift_plot_text", callback: textCallback)

        // Style
        engine.registerFunction(name: "_luaswift_plot_set_stroke", callback: setStrokeCallback)
        engine.registerFunction(name: "_luaswift_plot_set_fill", callback: setFillCallback)

        // Drawing
        engine.registerFunction(name: "_luaswift_plot_stroke", callback: strokeCallback)
        engine.registerFunction(name: "_luaswift_plot_fill", callback: fillCallback)

        // State
        engine.registerFunction(name: "_luaswift_plot_save", callback: saveCallback)
        engine.registerFunction(name: "_luaswift_plot_restore", callback: restoreCallback)

        // Export
        engine.registerFunction(name: "_luaswift_plot_to_svg", callback: toSVGCallback)
        engine.registerFunction(name: "_luaswift_plot_to_png", callback: toPNGCallback)
        engine.registerFunction(name: "_luaswift_plot_to_pdf", callback: toPDFCallback)
        engine.registerFunction(name: "_luaswift_plot_savefig", callback: saveFigCallback)

        // Set up Lua wrapper
        do {
            try engine.run(plotLuaWrapper)
        } catch {
            // Module setup failed silently
        }
    }

    // MARK: - Callbacks

    private static let createContextCallback: ([LuaValue]) throws -> LuaValue = { _ in
        let context = DrawingContext()
        let id = storeContext(context)
        return .number(Double(id))
    }

    private static let destroyContextCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let id = args.first?.intValue else { return .nil }
        removeContext(id)
        return .nil
    }

    private static let clearContextCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let id = args.first?.intValue,
              let context = getContext(id) else { return .nil }
        context.clear()
        return .nil
    }

    private static let commandCountCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let id = args.first?.intValue,
              let context = getContext(id) else { return .number(0) }
        return .number(Double(context.commandCount))
    }

    private static let moveToCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let id = args[0].intValue,
              let x = args[1].numberValue,
              let y = args[2].numberValue,
              let context = getContext(id) else { return .nil }
        context.moveTo(x, y)
        return .nil
    }

    private static let lineToCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let id = args[0].intValue,
              let x = args[1].numberValue,
              let y = args[2].numberValue,
              let context = getContext(id) else { return .nil }
        context.lineTo(x, y)
        return .nil
    }

    private static let curveToCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 7,
              let id = args[0].intValue,
              let cp1x = args[1].numberValue,
              let cp1y = args[2].numberValue,
              let cp2x = args[3].numberValue,
              let cp2y = args[4].numberValue,
              let x = args[5].numberValue,
              let y = args[6].numberValue,
              let context = getContext(id) else { return .nil }
        context.curveTo(cp1x: cp1x, cp1y: cp1y, cp2x: cp2x, cp2y: cp2y, x: x, y: y)
        return .nil
    }

    private static let closePathCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let id = args.first?.intValue,
              let context = getContext(id) else { return .nil }
        context.closePath()
        return .nil
    }

    private static let rectCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 5,
              let id = args[0].intValue,
              let x = args[1].numberValue,
              let y = args[2].numberValue,
              let w = args[3].numberValue,
              let h = args[4].numberValue,
              let context = getContext(id) else { return .nil }
        context.rect(x, y, w, h)
        return .nil
    }

    private static let ellipseCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 5,
              let id = args[0].intValue,
              let cx = args[1].numberValue,
              let cy = args[2].numberValue,
              let rx = args[3].numberValue,
              let ry = args[4].numberValue,
              let context = getContext(id) else { return .nil }
        context.ellipse(cx: cx, cy: cy, rx: rx, ry: ry)
        return .nil
    }

    private static let circleCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 4,
              let id = args[0].intValue,
              let cx = args[1].numberValue,
              let cy = args[2].numberValue,
              let r = args[3].numberValue,
              let context = getContext(id) else { return .nil }
        context.circle(cx: cx, cy: cy, r: r)
        return .nil
    }

    private static let textCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 4,
              let id = args[0].intValue,
              let text = args[1].stringValue,
              let x = args[2].numberValue,
              let y = args[3].numberValue,
              let context = getContext(id) else { return .nil }

        var style = TextStyle()

        // Parse style options from table if provided
        if args.count > 4, case .table(let opts) = args[4] {
            if let size = opts["font_size"]?.numberValue ?? opts["fontSize"]?.numberValue {
                style.fontSize = size
            }
            if let colorStr = opts["color"]?.stringValue {
                if let color = Color(hex: colorStr) ?? Color(name: colorStr) {
                    style.color = color
                }
            }
            if let anchor = opts["anchor"]?.stringValue {
                switch anchor {
                case "middle", "center": style.anchor = .middle
                case "end", "right": style.anchor = .end
                default: style.anchor = .start
                }
            }
            if let weight = opts["font_weight"]?.stringValue ?? opts["fontWeight"]?.stringValue {
                switch weight {
                case "bold": style.fontWeight = .bold
                case "light": style.fontWeight = .light
                default: style.fontWeight = .normal
                }
            }
        }

        context.text(text, x: x, y: y, style: style)
        return .nil
    }

    private static let setStrokeCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let id = args.first?.intValue,
              let context = getContext(id) else { return .nil }

        // Parse color
        if args.count > 1 {
            if let colorStr = args[1].stringValue {
                if let color = Color(hex: colorStr) ?? Color(name: colorStr) {
                    context.setStrokeColor(color)
                }
            }
        }

        // Parse width
        if args.count > 2, let width = args[2].numberValue {
            context.setStrokeWidth(width)
        }

        // Parse style
        if args.count > 3, let styleStr = args[3].stringValue {
            let style: LineStyle
            switch styleStr {
            case "-", "solid": style = .solid
            case "--", "dashed": style = .dashed
            case ":", "dotted": style = .dotted
            case "-.", "dashdot": style = .dashDot
            default: style = .solid
            }
            context.setStrokeStyle(style)
        }

        return .nil
    }

    private static let setFillCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 2,
              let id = args[0].intValue,
              let context = getContext(id) else { return .nil }

        if let colorStr = args[1].stringValue {
            if let color = Color(hex: colorStr) ?? Color(name: colorStr) {
                context.setFillColor(color)
            }
        }

        return .nil
    }

    private static let strokeCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let id = args.first?.intValue,
              let context = getContext(id) else { return .nil }
        context.strokePath()
        return .nil
    }

    private static let fillCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let id = args.first?.intValue,
              let context = getContext(id) else { return .nil }
        context.fillPath()
        return .nil
    }

    private static let saveCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let id = args.first?.intValue,
              let context = getContext(id) else { return .nil }
        context.saveState()
        return .nil
    }

    private static let restoreCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard let id = args.first?.intValue,
              let context = getContext(id) else { return .nil }
        context.restoreState()
        return .nil
    }

    private static let toSVGCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let id = args[0].intValue,
              let width = args[1].numberValue,
              let height = args[2].numberValue,
              let context = getContext(id) else { return .nil }
        let svg = context.renderToSVG(size: CGSize(width: width, height: height))
        return .string(svg)
    }

    #if canImport(ImageIO)
    private static let toPNGCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let id = args[0].intValue,
              let width = args[1].numberValue,
              let height = args[2].numberValue,
              let context = getContext(id) else { return .nil }

        let scale = args.count > 3 ? args[3].numberValue ?? 1.0 : 1.0

        guard let data = context.renderToPNG(size: CGSize(width: width, height: height), scale: scale) else {
            return .nil
        }
        return .string(String(data: data, encoding: .isoLatin1) ?? "")
    }

    private static let toPDFCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 3,
              let id = args[0].intValue,
              let width = args[1].numberValue,
              let height = args[2].numberValue,
              let context = getContext(id) else { return .nil }

        guard let data = context.renderToPDF(size: CGSize(width: width, height: height)) else {
            return .nil
        }
        return .string(String(data: data, encoding: .isoLatin1) ?? "")
    }

    private static let saveFigCallback: ([LuaValue]) throws -> LuaValue = { args in
        guard args.count >= 4,
              let id = args[0].intValue,
              let path = args[1].stringValue,
              let width = args[2].numberValue,
              let height = args[3].numberValue,
              let context = getContext(id) else {
            throw LuaError.runtimeError("savefig requires context id, path, width, height")
        }

        let size = CGSize(width: width, height: height)

        // Detect format from extension or options
        var format = "png"
        if args.count > 4, case .table(let opts) = args[4] {
            if let fmt = opts["format"]?.stringValue {
                format = fmt.lowercased()
            }
        }

        // Auto-detect from extension if not specified
        if format == "png" {
            let ext = (path as NSString).pathExtension.lowercased()
            if !ext.isEmpty {
                format = ext
            }
        }

        let data: Data?
        switch format {
        case "svg":
            let svg = context.renderToSVG(size: size)
            data = svg.data(using: .utf8)
        case "pdf":
            data = context.renderToPDF(size: size)
        default: // png
            let dpi = args.count > 4 && args[4].tableValue?["dpi"]?.numberValue != nil
                ? args[4].tableValue!["dpi"]!.numberValue! / 72.0
                : 1.0
            data = context.renderToPNG(size: size, scale: dpi)
        }

        guard let fileData = data else {
            throw LuaError.runtimeError("Failed to render \(format) data")
        }

        do {
            let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            try fileData.write(to: url)
            return .bool(true)
        } catch {
            throw LuaError.runtimeError("Failed to write file: \(error.localizedDescription)")
        }
    }
    #else
    private static let toPNGCallback: ([LuaValue]) throws -> LuaValue = { _ in
        throw LuaError.runtimeError("PNG export not available on this platform")
    }

    private static let toPDFCallback: ([LuaValue]) throws -> LuaValue = { _ in
        throw LuaError.runtimeError("PDF export not available on this platform")
    }

    private static let saveFigCallback: ([LuaValue]) throws -> LuaValue = { _ in
        throw LuaError.runtimeError("savefig not available on this platform")
    }
    #endif

    // MARK: - Lua Wrapper Code

    private static let plotLuaWrapper = """
    -- Create luaswift.plot namespace
    if not luaswift then luaswift = {} end
    luaswift.plot = {}
    local plot = luaswift.plot

    -- Capture function references
    local _create_context = _luaswift_plot_create_context
    local _destroy_context = _luaswift_plot_destroy_context
    local _clear_context = _luaswift_plot_clear_context
    local _command_count = _luaswift_plot_command_count
    local _move_to = _luaswift_plot_move_to
    local _line_to = _luaswift_plot_line_to
    local _curve_to = _luaswift_plot_curve_to
    local _close_path = _luaswift_plot_close_path
    local _rect = _luaswift_plot_rect
    local _ellipse = _luaswift_plot_ellipse
    local _circle = _luaswift_plot_circle
    local _text = _luaswift_plot_text
    local _set_stroke = _luaswift_plot_set_stroke
    local _set_fill = _luaswift_plot_set_fill
    local _stroke = _luaswift_plot_stroke
    local _fill = _luaswift_plot_fill
    local _save = _luaswift_plot_save
    local _restore = _luaswift_plot_restore
    local _to_svg = _luaswift_plot_to_svg
    local _to_png = _luaswift_plot_to_png
    local _to_pdf = _luaswift_plot_to_pdf
    local _savefig = _luaswift_plot_savefig

    -- DrawingContext class
    local DrawingContext = {}
    DrawingContext.__index = DrawingContext

    function DrawingContext:move_to(x, y) _move_to(self._id, x, y) return self end
    function DrawingContext:line_to(x, y) _line_to(self._id, x, y) return self end
    function DrawingContext:curve_to(cp1x, cp1y, cp2x, cp2y, x, y) _curve_to(self._id, cp1x, cp1y, cp2x, cp2y, x, y) return self end
    function DrawingContext:close_path() _close_path(self._id) return self end
    function DrawingContext:rect(x, y, w, h) _rect(self._id, x, y, w, h) return self end
    function DrawingContext:ellipse(cx, cy, rx, ry) _ellipse(self._id, cx, cy, rx, ry) return self end
    function DrawingContext:circle(cx, cy, r) _circle(self._id, cx, cy, r) return self end
    function DrawingContext:text(str, x, y, opts) _text(self._id, str, x, y, opts) return self end
    function DrawingContext:set_stroke(color, width, style) _set_stroke(self._id, color, width, style) return self end
    function DrawingContext:set_fill(color) _set_fill(self._id, color) return self end
    function DrawingContext:stroke() _stroke(self._id) return self end
    function DrawingContext:fill() _fill(self._id) return self end
    function DrawingContext:save() _save(self._id) return self end
    function DrawingContext:restore() _restore(self._id) return self end
    function DrawingContext:clear() _clear_context(self._id) return self end
    function DrawingContext:command_count() return _command_count(self._id) end

    function DrawingContext:to_svg(width, height)
        width = width or self._width or 640
        height = height or self._height or 480
        return _to_svg(self._id, width, height)
    end

    function DrawingContext:to_png(width, height, scale)
        width = width or self._width or 640
        height = height or self._height or 480
        scale = scale or 1
        return _to_png(self._id, width, height, scale)
    end

    function DrawingContext:to_pdf(width, height)
        width = width or self._width or 640
        height = height or self._height or 480
        return _to_pdf(self._id, width, height)
    end

    function DrawingContext:savefig(path, opts)
        opts = opts or {}
        local width = opts.width or self._width or 640
        local height = opts.height or self._height or 480
        return _savefig(self._id, path, width, height, opts)
    end

    function DrawingContext:destroy()
        if self._id then
            _destroy_context(self._id)
            self._id = nil
        end
    end

    DrawingContext.__gc = DrawingContext.destroy

    -- Convenience drawing methods
    function DrawingContext:line(x1, y1, x2, y2)
        return self:move_to(x1, y1):line_to(x2, y2):stroke()
    end

    function DrawingContext:filled_rect(x, y, w, h, fill, stroke)
        self:set_fill(fill or "white")
        self:rect(x, y, w, h)
        self:fill()
        if stroke then
            self:set_stroke(stroke)
            self:rect(x, y, w, h)
            self:stroke()
        end
        return self
    end

    function DrawingContext:filled_circle(cx, cy, r, fill, stroke)
        self:set_fill(fill or "white")
        self:circle(cx, cy, r)
        self:fill()
        if stroke then
            self:set_stroke(stroke)
            self:circle(cx, cy, r)
            self:stroke()
        end
        return self
    end

    -- Create context factory
    function plot.create_context(width, height)
        local id = _create_context()
        local ctx = setmetatable({
            _id = id,
            _width = width or 640,
            _height = height or 480,
            __luaswift_type = "plot.context"
        }, DrawingContext)
        return ctx
    end

    -- Figure class (matches matplotlib)
    local Figure = {}
    Figure.__index = Figure

    function Figure:get_context()
        return self._context
    end

    function Figure:savefig(path, opts)
        opts = opts or {}
        opts.width = opts.width or self._width
        opts.height = opts.height or self._height
        return self._context:savefig(path, opts)
    end

    function Figure:to_svg() return self._context:to_svg(self._width, self._height) end
    function Figure:to_png(opts)
        opts = opts or {}
        local dpi = opts.dpi or 72
        local scale = dpi / 72
        return self._context:to_png(self._width, self._height, scale)
    end
    function Figure:to_pdf() return self._context:to_pdf(self._width, self._height) end

    -- Axes class (matches matplotlib)
    local Axes = {}
    Axes.__index = Axes

    function Axes:get_context()
        return self._figure._context
    end

    -- Basic plot method (matches matplotlib ax.plot())
    function Axes:plot(x, y, opts)
        if type(y) == "table" and y[1] == nil then
            -- Called as ax:plot(x, opts) - y values only
            opts = y
            y = x
            x = nil
        end
        opts = opts or {}

        -- Generate x if not provided
        if not x then
            x = {}
            for i = 1, #y do x[i] = i end
        end

        -- Get styling
        local color = opts.color or opts.c or "blue"
        local linewidth = opts.linewidth or opts.lw or 1
        local linestyle = opts.linestyle or opts.ls or "-"

        local ctx = self:get_context()
        ctx:set_stroke(color, linewidth, linestyle)

        -- Draw line
        if #x > 0 then
            -- Transform data to figure coordinates
            local margin = 50
            local plot_width = self._figure._width - 2 * margin
            local plot_height = self._figure._height - 2 * margin

            -- Find data range
            local xmin, xmax = x[1], x[1]
            local ymin, ymax = y[1], y[1]
            for i = 2, #x do
                if x[i] < xmin then xmin = x[i] end
                if x[i] > xmax then xmax = x[i] end
                if y[i] < ymin then ymin = y[i] end
                if y[i] > ymax then ymax = y[i] end
            end

            -- Handle single-value range
            if xmax == xmin then xmax = xmin + 1 end
            if ymax == ymin then ymax = ymin + 1 end

            -- Transform function
            local function tx(v) return margin + (v - xmin) / (xmax - xmin) * plot_width end
            local function ty(v) return margin + (v - ymin) / (ymax - ymin) * plot_height end

            ctx:move_to(tx(x[1]), ty(y[1]))
            for i = 2, #x do
                ctx:line_to(tx(x[i]), ty(y[i]))
            end
            ctx:stroke()
        end

        -- Store for legend
        if opts.label then
            self._legend_entries = self._legend_entries or {}
            table.insert(self._legend_entries, {label = opts.label, color = color})
        end

        return self
    end

    -- Scatter plot (matches matplotlib ax.scatter())
    function Axes:scatter(x, y, opts)
        opts = opts or {}
        local s = opts.s or 20
        local c = opts.c or opts.color or "blue"
        local marker = opts.marker or "o"

        local ctx = self:get_context()
        local radius = math.sqrt(s) / 2

        -- Transform coordinates
        local margin = 50
        local plot_width = self._figure._width - 2 * margin
        local plot_height = self._figure._height - 2 * margin

        local xmin, xmax = x[1], x[1]
        local ymin, ymax = y[1], y[1]
        for i = 2, #x do
            if x[i] < xmin then xmin = x[i] end
            if x[i] > xmax then xmax = x[i] end
            if y[i] < ymin then ymin = y[i] end
            if y[i] > ymax then ymax = y[i] end
        end
        if xmax == xmin then xmax = xmin + 1 end
        if ymax == ymin then ymax = ymin + 1 end

        local function tx(v) return margin + (v - xmin) / (xmax - xmin) * plot_width end
        local function ty(v) return margin + (v - ymin) / (ymax - ymin) * plot_height end

        for i = 1, #x do
            ctx:set_fill(c)
            ctx:circle(tx(x[i]), ty(y[i]), radius)
            ctx:fill()
        end

        return self
    end

    -- Bar chart (matches matplotlib ax.bar())
    function Axes:bar(x, height, opts)
        opts = opts or {}
        local width = opts.width or 0.8
        local color = opts.color or "blue"
        local edgecolor = opts.edgecolor or "black"

        local ctx = self:get_context()

        local margin = 50
        local plot_width = self._figure._width - 2 * margin
        local plot_height = self._figure._height - 2 * margin

        local n = #x
        local bar_width = plot_width / n * width

        local hmax = height[1]
        for i = 2, #height do
            if height[i] > hmax then hmax = height[i] end
        end
        if hmax == 0 then hmax = 1 end

        for i = 1, n do
            local bx = margin + (i - 0.5) / n * plot_width - bar_width / 2
            local bh = height[i] / hmax * plot_height
            local by = margin

            ctx:set_fill(color)
            ctx:rect(bx, by, bar_width, bh)
            ctx:fill()
            ctx:set_stroke(edgecolor, 1)
            ctx:rect(bx, by, bar_width, bh)
            ctx:stroke()
        end

        return self
    end

    -- Histogram (matches matplotlib ax.hist())
    function Axes:hist(data, opts)
        opts = opts or {}
        local bins = opts.bins or 10
        local color = opts.color or "blue"
        local edgecolor = opts.edgecolor or "black"
        local density = opts.density or false
        local cumulative = opts.cumulative or false
        local alpha = opts.alpha or 1.0

        -- Find data range
        local dmin, dmax = data[1], data[1]
        for i = 2, #data do
            if data[i] < dmin then dmin = data[i] end
            if data[i] > dmax then dmax = data[i] end
        end

        -- Use specified range if provided
        if opts.range then
            dmin = opts.range[1]
            dmax = opts.range[2]
        end

        -- Handle edge case
        if dmax == dmin then dmax = dmin + 1 end

        -- Calculate bin edges
        local bin_edges = {}
        local bin_width = (dmax - dmin) / bins
        for i = 0, bins do
            bin_edges[i + 1] = dmin + i * bin_width
        end

        -- Count data in each bin
        local counts = {}
        for i = 1, bins do counts[i] = 0 end

        for _, v in ipairs(data) do
            if v >= dmin and v <= dmax then
                local bin_idx = math.floor((v - dmin) / bin_width) + 1
                if bin_idx > bins then bin_idx = bins end
                if bin_idx < 1 then bin_idx = 1 end
                counts[bin_idx] = counts[bin_idx] + 1
            end
        end

        -- Apply density normalization
        if density then
            local total = #data * bin_width
            for i = 1, bins do
                counts[i] = counts[i] / total
            end
        end

        -- Apply cumulative
        if cumulative then
            for i = 2, bins do
                counts[i] = counts[i] + counts[i - 1]
            end
        end

        -- Find max count for scaling
        local cmax = counts[1]
        for i = 2, bins do
            if counts[i] > cmax then cmax = counts[i] end
        end
        if cmax == 0 then cmax = 1 end

        -- Draw bars
        local ctx = self:get_context()
        local margin = 50
        local plot_width = self._figure._width - 2 * margin
        local plot_height = self._figure._height - 2 * margin

        local bar_width = plot_width / bins

        for i = 1, bins do
            local bx = margin + (i - 1) * bar_width
            local bh = counts[i] / cmax * plot_height
            local by = margin

            ctx:set_fill(color)
            ctx:rect(bx, by, bar_width, bh)
            ctx:fill()
            ctx:set_stroke(edgecolor, 1)
            ctx:rect(bx, by, bar_width, bh)
            ctx:stroke()
        end

        -- Store for legend
        if opts.label then
            self._legend_entries = self._legend_entries or {}
            table.insert(self._legend_entries, {label = opts.label, color = color})
        end

        -- Return (n, bins, patches) like matplotlib
        return counts, bin_edges, {}
    end

    -- Pie chart (matches matplotlib ax.pie())
    function Axes:pie(sizes, opts)
        opts = opts or {}
        local labels = opts.labels
        local colors = opts.colors or {"#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"}
        local explode = opts.explode
        local autopct = opts.autopct
        local startangle = opts.startangle or 0
        local counterclock = opts.counterclock
        if counterclock == nil then counterclock = true end

        local ctx = self:get_context()
        local cx = self._figure._width / 2
        local cy = self._figure._height / 2
        local radius = math.min(self._figure._width, self._figure._height) / 2 - 60

        -- Calculate total
        local total = 0
        for _, v in ipairs(sizes) do total = total + v end
        if total == 0 then total = 1 end

        -- Draw wedges
        local angle = startangle * math.pi / 180
        local direction = counterclock and 1 or -1

        for i, size in ipairs(sizes) do
            local sweep = (size / total) * 2 * math.pi * direction
            local mid_angle = angle + sweep / 2
            local color = colors[(i - 1) % #colors + 1]

            -- Calculate explode offset
            local offset_x, offset_y = 0, 0
            if explode and explode[i] then
                offset_x = math.cos(mid_angle) * explode[i] * radius * 0.2
                offset_y = math.sin(mid_angle) * explode[i] * radius * 0.2
            end

            local wcx = cx + offset_x
            local wcy = cy + offset_y

            -- Draw wedge as path
            ctx:set_fill(color)
            ctx:move_to(wcx, wcy)

            -- Approximate arc with line segments
            local segments = 32
            local start_a = angle
            local end_a = angle + sweep
            for j = 0, segments do
                local a = start_a + (end_a - start_a) * j / segments
                local px = wcx + radius * math.cos(a)
                local py = wcy + radius * math.sin(a)
                ctx:line_to(px, py)
            end
            ctx:close_path()
            ctx:fill()

            -- Draw edge
            ctx:set_stroke("white", 1)
            ctx:move_to(wcx, wcy)
            for j = 0, segments do
                local a = start_a + (end_a - start_a) * j / segments
                local px = wcx + radius * math.cos(a)
                local py = wcy + radius * math.sin(a)
                ctx:line_to(px, py)
            end
            ctx:close_path()
            ctx:stroke()

            -- Draw label
            if labels and labels[i] then
                local label_r = radius * 1.15
                local lx = wcx + label_r * math.cos(mid_angle)
                local ly = wcy + label_r * math.sin(mid_angle)
                local anchor = math.cos(mid_angle) >= 0 and "start" or "end"
                ctx:text(labels[i], lx, ly, {anchor = anchor, fontSize = 10})
            end

            -- Draw percentage
            if autopct then
                local pct = size / total * 100
                local pct_str = string.format(autopct, pct)
                local pct_r = radius * 0.6
                local px = wcx + pct_r * math.cos(mid_angle)
                local py = wcy + pct_r * math.sin(mid_angle)
                ctx:text(pct_str, px, py, {anchor = "middle", fontSize = 9, color = "white"})
            end

            angle = angle + sweep
        end

        return self
    end

    -- Legend (matches matplotlib ax.legend())
    function Axes:legend(opts)
        opts = opts or {}
        local loc = opts.loc or "upper right"
        local fontsize = opts.fontsize or 10
        local frameon = opts.frameon
        if frameon == nil then frameon = true end

        if not self._legend_entries or #self._legend_entries == 0 then
            return self
        end

        local ctx = self:get_context()
        local margin = 50

        -- Calculate legend position
        local lx, ly
        local lw = 100  -- legend width
        local lh = #self._legend_entries * 18 + 10  -- legend height

        if loc == "upper right" or loc == "best" then
            lx = self._figure._width - margin - lw - 10
            ly = self._figure._height - margin - 10
        elseif loc == "upper left" then
            lx = margin + 10
            ly = self._figure._height - margin - 10
        elseif loc == "lower right" then
            lx = self._figure._width - margin - lw - 10
            ly = margin + lh + 10
        elseif loc == "lower left" then
            lx = margin + 10
            ly = margin + lh + 10
        else
            lx = self._figure._width - margin - lw - 10
            ly = self._figure._height - margin - 10
        end

        -- Draw legend box
        if frameon then
            ctx:set_fill("white")
            ctx:rect(lx, ly - lh, lw, lh)
            ctx:fill()
            ctx:set_stroke("gray", 1)
            ctx:rect(lx, ly - lh, lw, lh)
            ctx:stroke()
        end

        -- Draw legend entries
        for i, entry in ipairs(self._legend_entries) do
            local ey = ly - 5 - (i - 1) * 18

            -- Color box
            ctx:set_fill(entry.color)
            ctx:rect(lx + 5, ey - 10, 15, 10)
            ctx:fill()

            -- Label
            ctx:text(entry.label, lx + 25, ey - 3, {fontSize = fontsize})
        end

        return self
    end

    -- Grid (matches matplotlib ax.grid())
    function Axes:grid(opts)
        if opts == false then return self end
        opts = opts or {}
        if type(opts) ~= "table" then opts = {} end

        local visible = opts.visible
        if visible == nil then visible = true end
        if not visible then return self end

        local which = opts.which or "major"
        local axis = opts.axis or "both"
        local color = opts.color or "#cccccc"
        local linestyle = opts.linestyle or "-"
        local linewidth = opts.linewidth or 0.5
        local alpha = opts.alpha or 0.7

        local ctx = self:get_context()
        local margin = 50
        local plot_width = self._figure._width - 2 * margin
        local plot_height = self._figure._height - 2 * margin

        ctx:set_stroke(color, linewidth, linestyle)

        -- Number of grid lines
        local nx = 10
        local ny = 10

        -- Draw vertical grid lines
        if axis == "both" or axis == "x" then
            for i = 0, nx do
                local gx = margin + i / nx * plot_width
                ctx:move_to(gx, margin)
                ctx:line_to(gx, margin + plot_height)
                ctx:stroke()
            end
        end

        -- Draw horizontal grid lines
        if axis == "both" or axis == "y" then
            for i = 0, ny do
                local gy = margin + i / ny * plot_height
                ctx:move_to(margin, gy)
                ctx:line_to(margin + plot_width, gy)
                ctx:stroke()
            end
        end

        return self
    end

    -- Axis limits (matches matplotlib)
    function Axes:set_xlim(left, right)
        self._xlim = {left, right}
        return self
    end

    function Axes:set_ylim(bottom, top)
        self._ylim = {bottom, top}
        return self
    end

    function Axes:get_xlim()
        return self._xlim or {0, 1}
    end

    function Axes:get_ylim()
        return self._ylim or {0, 1}
    end

    -- Aspect ratio (matches matplotlib)
    function Axes:set_aspect(aspect)
        self._aspect = aspect
        return self
    end

    -- Axis visibility (matches matplotlib)
    function Axes:axis(arg)
        if arg == "off" then
            self._axis_visible = false
        elseif arg == "on" then
            self._axis_visible = true
        elseif arg == "equal" then
            self._aspect = "equal"
        end
        return self
    end

    -- Imshow for heatmaps (matches matplotlib ax.imshow())
    function Axes:imshow(data, opts)
        opts = opts or {}
        local cmap = opts.cmap or "viridis"
        local vmin = opts.vmin
        local vmax = opts.vmax
        local aspect = opts.aspect or "auto"
        local interpolation = opts.interpolation or "nearest"

        -- Get data dimensions
        local nrows = #data
        local ncols = #data[1]

        -- Find data range
        if not vmin or not vmax then
            local dmin, dmax = data[1][1], data[1][1]
            for i = 1, nrows do
                for j = 1, ncols do
                    local v = data[i][j]
                    if v < dmin then dmin = v end
                    if v > dmax then dmax = v end
                end
            end
            vmin = vmin or dmin
            vmax = vmax or dmax
        end
        if vmax == vmin then vmax = vmin + 1 end

        -- Colormap lookup tables
        local colormaps = {
            viridis = function(t)
                local r = 0.267 + 0.004*t + 2.737*t^2 - 4.433*t^3 + 1.741*t^4
                local g = 0.004 + 1.384*t - 0.814*t^2 + 0.401*t^3
                local b = 0.329 + 1.422*t - 1.578*t^2 + 0.510*t^3
                return r, g, b
            end,
            plasma = function(t)
                local r = 0.050 + 2.735*t - 2.814*t^2 + 0.885*t^3
                local g = 0.030 + 0.114*t + 0.892*t^2 - 0.115*t^3
                local b = 0.528 + 1.266*t - 3.018*t^2 + 1.446*t^3
                return r, g, b
            end,
            inferno = function(t)
                local r = 0.001 + 1.244*t + 0.617*t^2 - 0.851*t^3
                local g = 0.001 + 0.047*t + 1.691*t^2 - 0.923*t^3
                local b = 0.014 + 1.689*t - 2.639*t^2 + 1.128*t^3
                return r, g, b
            end,
            gray = function(t)
                return t, t, t
            end,
            hot = function(t)
                local r = math.min(1, t * 3)
                local g = math.max(0, math.min(1, (t - 0.33) * 3))
                local b = math.max(0, math.min(1, (t - 0.67) * 3))
                return r, g, b
            end,
            cool = function(t)
                return t, 1 - t, 1
            end,
            coolwarm = function(t)
                if t < 0.5 then
                    local s = t * 2
                    return 0.227 + 0.706*s, 0.298 + 0.659*s, 0.753
                else
                    local s = (t - 0.5) * 2
                    return 0.706 + 0.294*s, 0.016 + 0.141*s, 0.150 - 0.133*s
                end
            end
        }

        local colormap = colormaps[cmap] or colormaps.viridis

        local ctx = self:get_context()
        local margin = 50
        local plot_width = self._figure._width - 2 * margin
        local plot_height = self._figure._height - 2 * margin

        local cell_width = plot_width / ncols
        local cell_height = plot_height / nrows

        -- Draw cells
        for i = 1, nrows do
            for j = 1, ncols do
                local v = data[i][j]
                local t = (v - vmin) / (vmax - vmin)
                t = math.max(0, math.min(1, t))
                local r, g, b = colormap(t)

                local hex = string.format("#%02X%02X%02X",
                    math.floor(r * 255),
                    math.floor(g * 255),
                    math.floor(b * 255))

                local x = margin + (j - 1) * cell_width
                local y = margin + (nrows - i) * cell_height

                ctx:set_fill(hex)
                ctx:rect(x, y, cell_width, cell_height)
                ctx:fill()
            end
        end

        -- Store colormap info for colorbar
        self._imshow_data = {vmin = vmin, vmax = vmax, cmap = cmap}

        return self
    end

    -- Error bar plot (matches matplotlib ax.errorbar())
    function Axes:errorbar(x, y, opts)
        opts = opts or {}
        local yerr = opts.yerr
        local xerr = opts.xerr
        local fmt = opts.fmt or "o"
        local color = opts.color or opts.c or "blue"
        local ecolor = opts.ecolor or color
        local elinewidth = opts.elinewidth or 1
        local capsize = opts.capsize or 3
        local capthick = opts.capthick or elinewidth

        local ctx = self:get_context()
        local margin = 50
        local plot_width = self._figure._width - 2 * margin
        local plot_height = self._figure._height - 2 * margin

        -- Find data range including errors
        local xmin, xmax = x[1], x[1]
        local ymin, ymax = y[1], y[1]

        for i = 1, #x do
            local xe = xerr and (type(xerr) == "number" and xerr or xerr[i]) or 0
            local ye = yerr and (type(yerr) == "number" and yerr or yerr[i]) or 0

            if x[i] - xe < xmin then xmin = x[i] - xe end
            if x[i] + xe > xmax then xmax = x[i] + xe end
            if y[i] - ye < ymin then ymin = y[i] - ye end
            if y[i] + ye > ymax then ymax = y[i] + ye end
        end

        if xmax == xmin then xmax = xmin + 1 end
        if ymax == ymin then ymax = ymin + 1 end

        local function tx(v) return margin + (v - xmin) / (xmax - xmin) * plot_width end
        local function ty(v) return margin + (v - ymin) / (ymax - ymin) * plot_height end

        -- Draw error bars
        ctx:set_stroke(ecolor, elinewidth)

        for i = 1, #x do
            local px = tx(x[i])
            local py = ty(y[i])

            -- Y error bar
            if yerr then
                local ye = type(yerr) == "number" and yerr or yerr[i]
                local y1 = ty(y[i] - ye)
                local y2 = ty(y[i] + ye)

                ctx:move_to(px, y1)
                ctx:line_to(px, y2)
                ctx:stroke()

                -- Caps
                if capsize > 0 then
                    ctx:move_to(px - capsize, y1)
                    ctx:line_to(px + capsize, y1)
                    ctx:stroke()
                    ctx:move_to(px - capsize, y2)
                    ctx:line_to(px + capsize, y2)
                    ctx:stroke()
                end
            end

            -- X error bar
            if xerr then
                local xe = type(xerr) == "number" and xerr or xerr[i]
                local x1 = tx(x[i] - xe)
                local x2 = tx(x[i] + xe)

                ctx:move_to(x1, py)
                ctx:line_to(x2, py)
                ctx:stroke()

                -- Caps
                if capsize > 0 then
                    ctx:move_to(x1, py - capsize)
                    ctx:line_to(x1, py + capsize)
                    ctx:stroke()
                    ctx:move_to(x2, py - capsize)
                    ctx:line_to(x2, py + capsize)
                    ctx:stroke()
                end
            end
        end

        -- Draw markers
        local radius = 4
        ctx:set_fill(color)
        for i = 1, #x do
            ctx:circle(tx(x[i]), ty(y[i]), radius)
            ctx:fill()
        end

        return self
    end

    -- Box plot (matches matplotlib ax.boxplot())
    function Axes:boxplot(data, opts)
        opts = opts or {}
        local positions = opts.positions
        local widths = opts.widths or 0.5
        local vert = opts.vert
        if vert == nil then vert = true end
        local showmeans = opts.showmeans or false
        local showfliers = opts.showfliers
        if showfliers == nil then showfliers = true end

        local ctx = self:get_context()
        local margin = 50
        local plot_width = self._figure._width - 2 * margin
        local plot_height = self._figure._height - 2 * margin

        -- Handle single dataset vs multiple
        local datasets = data
        if type(data[1]) == "number" then
            datasets = {data}
        end

        local n = #datasets

        -- Generate positions if not provided
        if not positions then
            positions = {}
            for i = 1, n do positions[i] = i end
        end

        -- Function to calculate percentile
        local function percentile(sorted, p)
            local idx = p / 100 * (#sorted - 1) + 1
            local lo = math.floor(idx)
            local hi = math.ceil(idx)
            if lo == hi then return sorted[lo] end
            return sorted[lo] + (sorted[hi] - sorted[lo]) * (idx - lo)
        end

        -- Find global range
        local gmin, gmax = math.huge, -math.huge
        for _, d in ipairs(datasets) do
            for _, v in ipairs(d) do
                if v < gmin then gmin = v end
                if v > gmax then gmax = v end
            end
        end
        if gmax == gmin then gmax = gmin + 1 end

        local box_width = plot_width / (n + 1) * (type(widths) == "number" and widths or 0.5)

        for idx, d in ipairs(datasets) do
            -- Sort data
            local sorted = {}
            for _, v in ipairs(d) do table.insert(sorted, v) end
            table.sort(sorted)

            -- Calculate statistics
            local q1 = percentile(sorted, 25)
            local q2 = percentile(sorted, 50)  -- median
            local q3 = percentile(sorted, 75)
            local iqr = q3 - q1

            -- Whiskers (1.5 * IQR)
            local whisker_lo = q1 - 1.5 * iqr
            local whisker_hi = q3 + 1.5 * iqr

            -- Find actual whisker ends within data
            local wlo, whi = sorted[1], sorted[#sorted]
            for _, v in ipairs(sorted) do
                if v >= whisker_lo then wlo = v; break end
            end
            for i = #sorted, 1, -1 do
                if sorted[i] <= whisker_hi then whi = sorted[i]; break end
            end

            -- Transform
            local function ty(v) return margin + (v - gmin) / (gmax - gmin) * plot_height end
            local px = margin + positions[idx] / (n + 1) * plot_width

            -- Draw box
            local y1 = ty(q1)
            local y3 = ty(q3)
            local box_h = y3 - y1

            ctx:set_fill("white")
            ctx:rect(px - box_width/2, y1, box_width, box_h)
            ctx:fill()
            ctx:set_stroke("black", 1)
            ctx:rect(px - box_width/2, y1, box_width, box_h)
            ctx:stroke()

            -- Draw median line
            ctx:set_stroke("orange", 2)
            local y2 = ty(q2)
            ctx:move_to(px - box_width/2, y2)
            ctx:line_to(px + box_width/2, y2)
            ctx:stroke()

            -- Draw whiskers
            ctx:set_stroke("black", 1)
            -- Lower whisker
            ctx:move_to(px, y1)
            ctx:line_to(px, ty(wlo))
            ctx:stroke()
            ctx:move_to(px - box_width/4, ty(wlo))
            ctx:line_to(px + box_width/4, ty(wlo))
            ctx:stroke()
            -- Upper whisker
            ctx:move_to(px, y3)
            ctx:line_to(px, ty(whi))
            ctx:stroke()
            ctx:move_to(px - box_width/4, ty(whi))
            ctx:line_to(px + box_width/4, ty(whi))
            ctx:stroke()

            -- Draw fliers (outliers)
            if showfliers then
                ctx:set_fill("black")
                for _, v in ipairs(sorted) do
                    if v < whisker_lo or v > whisker_hi then
                        ctx:circle(px, ty(v), 3)
                        ctx:fill()
                    end
                end
            end

            -- Draw mean
            if showmeans then
                local mean = 0
                for _, v in ipairs(d) do mean = mean + v end
                mean = mean / #d
                ctx:set_stroke("green", 1, "--")
                local my = ty(mean)
                ctx:move_to(px - box_width/2, my)
                ctx:line_to(px + box_width/2, my)
                ctx:stroke()
            end
        end

        return self
    end

    -- Contour plot (matches matplotlib ax.contour())
    function Axes:contour(X, Y, Z, opts)
        opts = opts or {}
        local levels = opts.levels or 10
        local colors = opts.colors or {"black"}
        local linewidths = opts.linewidths or 1

        -- Simple implementation using marching squares approximation
        local ctx = self:get_context()
        local margin = 50
        local plot_width = self._figure._width - 2 * margin
        local plot_height = self._figure._height - 2 * margin

        -- Get dimensions
        local nrows = #Z
        local ncols = #Z[1]

        -- Find Z range
        local zmin, zmax = Z[1][1], Z[1][1]
        for i = 1, nrows do
            for j = 1, ncols do
                if Z[i][j] < zmin then zmin = Z[i][j] end
                if Z[i][j] > zmax then zmax = Z[i][j] end
            end
        end

        -- Calculate level values
        local level_values = {}
        if type(levels) == "number" then
            for i = 1, levels do
                level_values[i] = zmin + (i - 0.5) / levels * (zmax - zmin)
            end
        else
            level_values = levels
        end

        -- Transform functions
        local xmin, xmax = X[1][1], X[1][ncols]
        local ymin, ymax = Y[1][1], Y[nrows][1]

        local function tx(v) return margin + (v - xmin) / (xmax - xmin) * plot_width end
        local function ty(v) return margin + (v - ymin) / (ymax - ymin) * plot_height end

        -- Draw contour lines using simple threshold crossing
        for li, level in ipairs(level_values) do
            local color = colors[(li - 1) % #colors + 1]
            ctx:set_stroke(color, type(linewidths) == "number" and linewidths or linewidths[(li - 1) % #linewidths + 1])

            -- Check each cell
            for i = 1, nrows - 1 do
                for j = 1, ncols - 1 do
                    -- Get corner values
                    local v00 = Z[i][j]
                    local v10 = Z[i][j + 1]
                    local v01 = Z[i + 1][j]
                    local v11 = Z[i + 1][j + 1]

                    -- Check for level crossing
                    local above00 = v00 >= level
                    local above10 = v10 >= level
                    local above01 = v01 >= level
                    local above11 = v11 >= level

                    -- Linear interpolation for crossing points
                    local function interp(v1, v2, x1, x2)
                        if v2 == v1 then return (x1 + x2) / 2 end
                        local t = (level - v1) / (v2 - v1)
                        return x1 + t * (x2 - x1)
                    end

                    -- Get cell coordinates
                    local x0, x1 = X[i][j], X[i][j + 1]
                    local y0, y1 = Y[i][j], Y[i + 1][j]

                    -- Simple crossing detection
                    local crossings = {}

                    -- Bottom edge
                    if above00 ~= above10 then
                        local cx = interp(v00, v10, x0, x1)
                        table.insert(crossings, {tx(cx), ty(y0)})
                    end
                    -- Top edge
                    if above01 ~= above11 then
                        local cx = interp(v01, v11, x0, x1)
                        table.insert(crossings, {tx(cx), ty(y1)})
                    end
                    -- Left edge
                    if above00 ~= above01 then
                        local cy = interp(v00, v01, y0, y1)
                        table.insert(crossings, {tx(x0), ty(cy)})
                    end
                    -- Right edge
                    if above10 ~= above11 then
                        local cy = interp(v10, v11, y0, y1)
                        table.insert(crossings, {tx(x1), ty(cy)})
                    end

                    -- Draw line segment if we have 2 crossings
                    if #crossings == 2 then
                        ctx:move_to(crossings[1][1], crossings[1][2])
                        ctx:line_to(crossings[2][1], crossings[2][2])
                        ctx:stroke()
                    end
                end
            end
        end

        return self
    end

    -- Filled contour plot (matches matplotlib ax.contourf())
    function Axes:contourf(X, Y, Z, opts)
        -- For filled contours, we use imshow as approximation
        return self:imshow(Z, opts)
    end

    -- Colorbar (matches matplotlib fig.colorbar())
    function Figure:colorbar(mappable, opts)
        opts = opts or {}
        local ax = opts.ax or self._axes[1]

        if not ax or not ax._imshow_data then
            return self
        end

        local ctx = self._context
        local vmin = ax._imshow_data.vmin
        local vmax = ax._imshow_data.vmax
        local cmap = ax._imshow_data.cmap

        -- Colormap lookup
        local colormaps = {
            viridis = function(t)
                local r = 0.267 + 0.004*t + 2.737*t^2 - 4.433*t^3 + 1.741*t^4
                local g = 0.004 + 1.384*t - 0.814*t^2 + 0.401*t^3
                local b = 0.329 + 1.422*t - 1.578*t^2 + 0.510*t^3
                return r, g, b
            end,
            gray = function(t) return t, t, t end,
            hot = function(t)
                local r = math.min(1, t * 3)
                local g = math.max(0, math.min(1, (t - 0.33) * 3))
                local b = math.max(0, math.min(1, (t - 0.67) * 3))
                return r, g, b
            end
        }
        local colormap = colormaps[cmap] or colormaps.viridis

        -- Draw colorbar on right side
        local cb_width = 20
        local cb_height = self._height - 120
        local cb_x = self._width - 50
        local cb_y = 60

        local n_steps = 50
        for i = 0, n_steps - 1 do
            local t = i / (n_steps - 1)
            local r, g, b = colormap(t)
            local hex = string.format("#%02X%02X%02X",
                math.floor(r * 255),
                math.floor(g * 255),
                math.floor(b * 255))

            ctx:set_fill(hex)
            ctx:rect(cb_x, cb_y + i * cb_height / n_steps, cb_width, cb_height / n_steps + 1)
            ctx:fill()
        end

        -- Draw border
        ctx:set_stroke("black", 1)
        ctx:rect(cb_x, cb_y, cb_width, cb_height)
        ctx:stroke()

        -- Draw tick labels
        local n_ticks = 5
        for i = 0, n_ticks do
            local t = i / n_ticks
            local val = vmin + t * (vmax - vmin)
            local tick_label = string.format("%.2g", val)
            local ly = cb_y + (1 - t) * cb_height
            ctx:text(tick_label, cb_x + cb_width + 5, ly, {fontSize = 9})
        end

        -- Draw colorbar label if provided
        if opts.label then
            ctx:save()
            -- Draw label rotated 90 degrees to the right of tick labels
            ctx:text(opts.label, cb_x + cb_width + 40, cb_y + cb_height / 2, {
                fontSize = 11,
                anchor = "middle",
                rotation = -90
            })
            ctx:restore()
        end

        return self
    end

    -- Title, labels (matches matplotlib)
    function Axes:set_title(title, opts)
        opts = opts or {}
        local ctx = self:get_context()
        ctx:text(title, self._figure._width / 2, self._figure._height - 20, {
            anchor = "middle",
            fontSize = opts.fontsize or 14,
            fontWeight = "bold"
        })
        return self
    end

    function Axes:set_xlabel(label, opts)
        opts = opts or {}
        local ctx = self:get_context()
        ctx:text(label, self._figure._width / 2, 20, {
            anchor = "middle",
            fontSize = opts.fontsize or 12
        })
        return self
    end

    function Axes:set_ylabel(label, opts)
        opts = opts or {}
        local ctx = self:get_context()
        -- Note: vertical text rotation would require transform
        ctx:text(label, 15, self._figure._height / 2, {
            anchor = "middle",
            fontSize = opts.fontsize or 12
        })
        return self
    end

    -- Create figure factory (matches matplotlib plt.figure())
    function plot.figure(opts)
        opts = opts or {}
        local figsize = opts.figsize or {6.4, 4.8}
        local dpi = opts.dpi or 100
        local width = figsize[1] * dpi
        local height = figsize[2] * dpi

        local ctx = plot.create_context(width, height)

        -- Draw white background
        ctx:set_fill("white")
        ctx:rect(0, 0, width, height)
        ctx:fill()

        local fig = setmetatable({
            _context = ctx,
            _width = width,
            _height = height,
            _dpi = dpi,
            _axes = {},
            __luaswift_type = "plot.figure"
        }, Figure)

        return fig
    end

    -- Create subplots (matches matplotlib plt.subplots())
    function plot.subplots(nrows, ncols, opts)
        -- Handle case where options are passed as first argument
        if type(nrows) == "table" then
            opts = nrows
            nrows = 1
            ncols = 1
        elseif type(ncols) == "table" then
            opts = ncols
            ncols = 1
        end
        nrows = nrows or 1
        ncols = ncols or 1
        opts = opts or {}

        local fig = plot.figure(opts)

        local axes = {}
        for r = 1, nrows do
            for c = 1, ncols do
                local ax = setmetatable({
                    _figure = fig,
                    _row = r,
                    _col = c,
                    __luaswift_type = "plot.axes"
                }, Axes)
                table.insert(axes, ax)
                table.insert(fig._axes, ax)
            end
        end

        if nrows == 1 and ncols == 1 then
            return fig, axes[1]
        else
            return fig, axes
        end
    end

    -- plt.show() - no-op in embedded context
    function plot.show()
        -- No GUI in embedded context
    end

    -- ============================================================
    -- Statistical Plots Namespace (luaswift.plot.stat)
    -- Seaborn-compatible statistical visualizations
    -- ============================================================

    plot.stat = {}
    local stat = plot.stat

    -- Kernel Density Estimation helper
    local function kde(data, x_grid, bandwidth)
        local n = #data
        if n == 0 then return {} end

        -- Scott's rule for bandwidth if not specified
        if not bandwidth then
            local mean = 0
            for _, v in ipairs(data) do mean = mean + v end
            mean = mean / n

            local variance = 0
            for _, v in ipairs(data) do
                variance = variance + (v - mean)^2
            end
            local std = math.sqrt(variance / n)
            bandwidth = std * n^(-0.2)  -- Scott's rule
            if bandwidth == 0 then bandwidth = 1 end
        end

        local density = {}
        local sqrt2pi = math.sqrt(2 * math.pi)

        for i, x in ipairs(x_grid) do
            local sum = 0
            for _, xi in ipairs(data) do
                local z = (x - xi) / bandwidth
                sum = sum + math.exp(-0.5 * z * z) / sqrt2pi
            end
            density[i] = sum / (n * bandwidth)
        end

        return density
    end

    -- Generate grid for KDE
    local function linspace(start, stop, n)
        local result = {}
        if n == 1 then
            result[1] = start
        else
            local step = (stop - start) / (n - 1)
            for i = 1, n do
                result[i] = start + (i - 1) * step
            end
        end
        return result
    end

    -- histplot (matches seaborn sns.histplot)
    function stat.histplot(ax, data, opts)
        opts = opts or {}
        local stat_type = opts.stat or "count"
        local kde_overlay = opts.kde or false
        local bins = opts.bins or 10
        local binwidth = opts.binwidth
        local color = opts.color or "steelblue"
        local edgecolor = opts.edgecolor or "white"
        local alpha = opts.alpha or 0.7
        local element = opts.element or "bars"
        local fill = opts.fill
        if fill == nil then fill = true end

        -- Calculate bin edges
        local dmin, dmax = data[1], data[1]
        for _, v in ipairs(data) do
            if v < dmin then dmin = v end
            if v > dmax then dmax = v end
        end

        local bin_edges = {}
        if binwidth then
            bins = math.ceil((dmax - dmin) / binwidth)
        end

        for i = 0, bins do
            bin_edges[i + 1] = dmin + i * (dmax - dmin) / bins
        end

        -- Count values in bins
        local counts = {}
        for i = 1, bins do counts[i] = 0 end

        for _, v in ipairs(data) do
            for i = 1, bins do
                if v >= bin_edges[i] and (v < bin_edges[i + 1] or (i == bins and v == bin_edges[i + 1])) then
                    counts[i] = counts[i] + 1
                    break
                end
            end
        end

        -- Apply stat transformation
        local n = #data
        local heights = {}
        local bin_widths = (dmax - dmin) / bins

        for i = 1, bins do
            if stat_type == "count" then
                heights[i] = counts[i]
            elseif stat_type == "frequency" then
                heights[i] = counts[i] / n
            elseif stat_type == "probability" then
                heights[i] = counts[i] / n
            elseif stat_type == "percent" then
                heights[i] = (counts[i] / n) * 100
            elseif stat_type == "density" then
                heights[i] = counts[i] / (n * bin_widths)
            else
                heights[i] = counts[i]
            end
        end

        -- Draw histogram
        local ctx = ax:get_context()
        local margin = 50
        local plot_width = ax._figure._width - 2 * margin
        local plot_height = ax._figure._height - 2 * margin

        local max_height = heights[1]
        for _, h in ipairs(heights) do
            if h > max_height then max_height = h end
        end
        if max_height == 0 then max_height = 1 end

        if element == "bars" then
            for i = 1, bins do
                local x = margin + (bin_edges[i] - dmin) / (dmax - dmin) * plot_width
                local w = bin_widths / (dmax - dmin) * plot_width
                local h = heights[i] / max_height * plot_height
                local y = margin + plot_height - h

                if fill then
                    ctx:set_fill(color)
                    ctx:rect(x, y, w, h)
                    ctx:fill()
                end

                ctx:set_stroke(edgecolor, 1)
                ctx:rect(x, y, w, h)
                ctx:stroke()
            end
        elseif element == "step" then
            ctx:set_stroke(color, 2)
            ctx:move_to(margin, margin + plot_height)
            for i = 1, bins do
                local x1 = margin + (bin_edges[i] - dmin) / (dmax - dmin) * plot_width
                local x2 = margin + (bin_edges[i + 1] - dmin) / (dmax - dmin) * plot_width
                local h = heights[i] / max_height * plot_height
                local y = margin + plot_height - h
                ctx:line_to(x1, y)
                ctx:line_to(x2, y)
            end
            ctx:line_to(margin + plot_width, margin + plot_height)
            ctx:stroke()
        end

        -- KDE overlay
        if kde_overlay then
            local n_points = 100
            local x_grid = linspace(dmin, dmax, n_points)
            local density = kde(data, x_grid, opts.bw_adjust)

            local max_density = density[1]
            for _, d in ipairs(density) do
                if d > max_density then max_density = d end
            end

            -- Scale KDE to match histogram
            local scale = max_height / max_density

            ctx:set_stroke("darkblue", 2)
            for i, x in ipairs(x_grid) do
                local px = margin + (x - dmin) / (dmax - dmin) * plot_width
                local py = margin + plot_height - density[i] * scale / max_height * plot_height
                if i == 1 then
                    ctx:move_to(px, py)
                else
                    ctx:line_to(px, py)
                end
            end
            ctx:stroke()
        end

        return ax
    end

    -- kdeplot (matches seaborn sns.kdeplot)
    function stat.kdeplot(ax, data, opts)
        opts = opts or {}
        local bw_method = opts.bw_method or "scott"
        local bw_adjust = opts.bw_adjust or 1.0
        local fill = opts.fill or false
        local color = opts.color or "blue"
        local alpha = opts.alpha or 0.3
        local linewidth = opts.linewidth or 2
        local cumulative = opts.cumulative or false
        local cut = opts.cut or 3

        -- Calculate bandwidth
        local n = #data
        if n == 0 then return ax end

        local mean = 0
        for _, v in ipairs(data) do mean = mean + v end
        mean = mean / n

        local variance = 0
        for _, v in ipairs(data) do
            variance = variance + (v - mean)^2
        end
        local std = math.sqrt(variance / n)

        local bandwidth
        if type(bw_method) == "number" then
            bandwidth = bw_method
        elseif bw_method == "scott" then
            bandwidth = std * n^(-0.2)
        elseif bw_method == "silverman" then
            -- IQR calculation
            local sorted = {}
            for i, v in ipairs(data) do sorted[i] = v end
            table.sort(sorted)
            local q1_idx = math.floor(n * 0.25)
            local q3_idx = math.floor(n * 0.75)
            local iqr = sorted[math.max(1, q3_idx)] - sorted[math.max(1, q1_idx)]
            bandwidth = 0.9 * math.min(std, iqr / 1.34) * n^(-0.2)
        else
            bandwidth = std * n^(-0.2)
        end

        bandwidth = bandwidth * bw_adjust
        if bandwidth == 0 then bandwidth = 1 end

        -- Data range with cut extension
        local dmin, dmax = data[1], data[1]
        for _, v in ipairs(data) do
            if v < dmin then dmin = v end
            if v > dmax then dmax = v end
        end
        dmin = dmin - cut * bandwidth
        dmax = dmax + cut * bandwidth

        -- Generate KDE
        local n_points = 200
        local x_grid = linspace(dmin, dmax, n_points)
        local density = kde(data, x_grid, bandwidth)

        -- Cumulative if requested
        if cumulative then
            local cum = 0
            local dx = (dmax - dmin) / (n_points - 1)
            for i = 1, n_points do
                cum = cum + density[i] * dx
                density[i] = cum
            end
        end

        -- Draw
        local ctx = ax:get_context()
        local margin = 50
        local plot_width = ax._figure._width - 2 * margin
        local plot_height = ax._figure._height - 2 * margin

        local max_density = density[1]
        for _, d in ipairs(density) do
            if d > max_density then max_density = d end
        end
        if max_density == 0 then max_density = 1 end

        -- Fill under curve
        if fill then
            ctx:set_fill(color)
            ctx:move_to(margin, margin + plot_height)
            for i, x in ipairs(x_grid) do
                local px = margin + (x - dmin) / (dmax - dmin) * plot_width
                local py = margin + plot_height - density[i] / max_density * plot_height
                ctx:line_to(px, py)
            end
            ctx:line_to(margin + plot_width, margin + plot_height)
            ctx:close_path()
            ctx:fill()
        end

        -- Draw line
        ctx:set_stroke(color, linewidth)
        for i, x in ipairs(x_grid) do
            local px = margin + (x - dmin) / (dmax - dmin) * plot_width
            local py = margin + plot_height - density[i] / max_density * plot_height
            if i == 1 then
                ctx:move_to(px, py)
            else
                ctx:line_to(px, py)
            end
        end
        ctx:stroke()

        return ax
    end

    -- rugplot (matches seaborn sns.rugplot)
    function stat.rugplot(ax, data, opts)
        opts = opts or {}
        local height = opts.height or 0.05
        local color = opts.color or "black"
        local linewidth = opts.linewidth or 1
        local alpha = opts.alpha or 1.0
        local axis = opts.axis or "x"

        local ctx = ax:get_context()
        local margin = 50
        local plot_width = ax._figure._width - 2 * margin
        local plot_height = ax._figure._height - 2 * margin

        local dmin, dmax = data[1], data[1]
        for _, v in ipairs(data) do
            if v < dmin then dmin = v end
            if v > dmax then dmax = v end
        end

        ctx:set_stroke(color, linewidth)

        local rug_height = height * plot_height

        for _, v in ipairs(data) do
            if axis == "x" then
                local x = margin + (v - dmin) / (dmax - dmin) * plot_width
                ctx:move_to(x, margin + plot_height)
                ctx:line_to(x, margin + plot_height - rug_height)
            else
                local y = margin + plot_height - (v - dmin) / (dmax - dmin) * plot_height
                ctx:move_to(margin, y)
                ctx:line_to(margin + rug_height, y)
            end
        end
        ctx:stroke()

        return ax
    end

    -- violinplot (matches matplotlib ax.violinplot)
    function stat.violinplot(ax, data, opts)
        opts = opts or {}
        local positions = opts.positions
        local widths = opts.widths or 0.5
        local showmeans = opts.showmeans or false
        local showmedians = opts.showmedians or true
        local showextrema = opts.showextrema or true
        local bw_method = opts.bw_method or "scott"
        local vert = opts.vert
        if vert == nil then vert = true end

        local ctx = ax:get_context()
        local margin = 50
        local plot_width = ax._figure._width - 2 * margin
        local plot_height = ax._figure._height - 2 * margin

        -- Handle single dataset
        if type(data[1]) == "number" then
            data = {data}
        end

        local n_datasets = #data

        -- Default positions
        if not positions then
            positions = {}
            for i = 1, n_datasets do positions[i] = i end
        end

        -- Find global data range for scaling
        local global_min, global_max = data[1][1], data[1][1]
        for _, dataset in ipairs(data) do
            for _, v in ipairs(dataset) do
                if v < global_min then global_min = v end
                if v > global_max then global_max = v end
            end
        end
        if global_max == global_min then global_max = global_min + 1 end

        local pos_min, pos_max = positions[1], positions[1]
        for _, p in ipairs(positions) do
            if p < pos_min then pos_min = p end
            if p > pos_max then pos_max = p end
        end
        local pos_range = pos_max - pos_min
        if pos_range == 0 then pos_range = 1 end

        for idx, dataset in ipairs(data) do
            local pos = positions[idx]
            local n = #dataset

            -- Sort for statistics
            local sorted = {}
            for i, v in ipairs(dataset) do sorted[i] = v end
            table.sort(sorted)

            -- Calculate bandwidth (Scott's rule)
            local mean_val = 0
            for _, v in ipairs(dataset) do mean_val = mean_val + v end
            mean_val = mean_val / n

            local variance = 0
            for _, v in ipairs(dataset) do
                variance = variance + (v - mean_val)^2
            end
            local std = math.sqrt(variance / n)
            local bandwidth = std * n^(-0.2)
            if bandwidth == 0 then bandwidth = 1 end

            -- KDE
            local dmin, dmax = sorted[1], sorted[n]
            local cut = 2
            local kde_min = dmin - cut * bandwidth
            local kde_max = dmax + cut * bandwidth

            local n_points = 50
            local y_grid = linspace(kde_min, kde_max, n_points)
            local density = kde(dataset, y_grid, bandwidth)

            local max_density = density[1]
            for _, d in ipairs(density) do
                if d > max_density then max_density = d end
            end
            if max_density == 0 then max_density = 1 end

            -- Scale width
            local width = widths
            if type(widths) == "table" then width = widths[idx] or 0.5 end

            -- Draw violin
            if vert then
                local cx = margin + (pos - pos_min) / pos_range * plot_width * 0.8 + plot_width * 0.1

                -- Right side
                ctx:set_fill("#4878CF")
                ctx:move_to(cx, margin + plot_height - (y_grid[1] - global_min) / (global_max - global_min) * plot_height)
                for i, y in ipairs(y_grid) do
                    local py = margin + plot_height - (y - global_min) / (global_max - global_min) * plot_height
                    local w = density[i] / max_density * width * plot_width / (n_datasets + 1) * 0.5
                    ctx:line_to(cx + w, py)
                end
                -- Left side (mirror)
                for i = n_points, 1, -1 do
                    local y = y_grid[i]
                    local py = margin + plot_height - (y - global_min) / (global_max - global_min) * plot_height
                    local w = density[i] / max_density * width * plot_width / (n_datasets + 1) * 0.5
                    ctx:line_to(cx - w, py)
                end
                ctx:close_path()
                ctx:fill()

                -- Outline
                ctx:set_stroke("black", 1)
                ctx:move_to(cx, margin + plot_height - (y_grid[1] - global_min) / (global_max - global_min) * plot_height)
                for i, y in ipairs(y_grid) do
                    local py = margin + plot_height - (y - global_min) / (global_max - global_min) * plot_height
                    local w = density[i] / max_density * width * plot_width / (n_datasets + 1) * 0.5
                    ctx:line_to(cx + w, py)
                end
                for i = n_points, 1, -1 do
                    local y = y_grid[i]
                    local py = margin + plot_height - (y - global_min) / (global_max - global_min) * plot_height
                    local w = density[i] / max_density * width * plot_width / (n_datasets + 1) * 0.5
                    ctx:line_to(cx - w, py)
                end
                ctx:close_path()
                ctx:stroke()

                -- Median line
                if showmedians then
                    local median = sorted[math.ceil(n / 2)]
                    local my = margin + plot_height - (median - global_min) / (global_max - global_min) * plot_height
                    local mw = width * plot_width / (n_datasets + 1) * 0.3
                    ctx:set_stroke("white", 2)
                    ctx:move_to(cx - mw, my)
                    ctx:line_to(cx + mw, my)
                    ctx:stroke()
                end

                -- Mean marker
                if showmeans then
                    local my = margin + plot_height - (mean_val - global_min) / (global_max - global_min) * plot_height
                    ctx:set_fill("white")
                    ctx:circle(cx, my, 3)
                    ctx:fill()
                end

                -- Extrema
                if showextrema then
                    local min_y = margin + plot_height - (sorted[1] - global_min) / (global_max - global_min) * plot_height
                    local max_y = margin + plot_height - (sorted[n] - global_min) / (global_max - global_min) * plot_height
                    ctx:set_stroke("black", 1)
                    ctx:move_to(cx, min_y)
                    ctx:line_to(cx, max_y)
                    ctx:stroke()
                end
            end
        end

        return ax
    end

    -- stripplot (matches seaborn sns.stripplot)
    function stat.stripplot(ax, data, opts)
        opts = opts or {}
        local x = opts.x
        local y = opts.y
        local jitter = opts.jitter
        if jitter == nil then jitter = 0.2 end
        local color = opts.color or "steelblue"
        local size = opts.size or opts.s or 5
        local alpha = opts.alpha or 0.7
        local orient = opts.orient or "v"

        local ctx = ax:get_context()
        local margin = 50
        local plot_width = ax._figure._width - 2 * margin
        local plot_height = ax._figure._height - 2 * margin

        -- Handle single dataset
        if type(data[1]) == "number" then
            data = {data}
        end

        local n_datasets = #data

        -- Find global data range for scaling
        local global_min, global_max = data[1][1], data[1][1]
        for _, dataset in ipairs(data) do
            for _, v in ipairs(dataset) do
                if v < global_min then global_min = v end
                if v > global_max then global_max = v end
            end
        end
        if global_max == global_min then global_max = global_min + 1 end

        ctx:set_fill(color)

        for idx, dataset in ipairs(data) do
            local base_x = margin + (idx - 0.5) / n_datasets * plot_width

            for _, v in ipairs(dataset) do
                local jit = 0
                if jitter then
                    jit = (math.random() - 0.5) * 2 * jitter * plot_width / n_datasets * 0.3
                end

                if orient == "v" then
                    local px = base_x + jit
                    local py = margin + plot_height - (v - global_min) / (global_max - global_min) * plot_height
                    ctx:circle(px, py, size / 2)
                    ctx:fill()
                else
                    local py = base_x + jit
                    local px = margin + (v - global_min) / (global_max - global_min) * plot_width
                    ctx:circle(px, py, size / 2)
                    ctx:fill()
                end
            end
        end

        return ax
    end

    -- swarmplot (matches seaborn sns.swarmplot)
    -- Uses beeswarm algorithm to avoid overlap
    function stat.swarmplot(ax, data, opts)
        opts = opts or {}
        local color = opts.color or "steelblue"
        local size = opts.size or opts.s or 5
        local alpha = opts.alpha or 0.7
        local orient = opts.orient or "v"

        local ctx = ax:get_context()
        local margin = 50
        local plot_width = ax._figure._width - 2 * margin
        local plot_height = ax._figure._height - 2 * margin

        -- Handle single dataset
        if type(data[1]) == "number" then
            data = {data}
        end

        local n_datasets = #data
        local point_radius = size / 2

        -- Find global data range for scaling
        local global_min, global_max = data[1][1], data[1][1]
        for _, dataset in ipairs(data) do
            for _, v in ipairs(dataset) do
                if v < global_min then global_min = v end
                if v > global_max then global_max = v end
            end
        end
        if global_max == global_min then global_max = global_min + 1 end

        ctx:set_fill(color)

        for idx, dataset in ipairs(data) do
            local base_x = margin + (idx - 0.5) / n_datasets * plot_width
            local max_width = plot_width / n_datasets * 0.4

            -- Sort data for beeswarm
            local sorted = {}
            for i, v in ipairs(dataset) do
                sorted[i] = {value = v, index = i}
            end
            table.sort(sorted, function(a, b) return a.value < b.value end)

            -- Place points using simple beeswarm
            local placed = {}  -- {y, x_offset}

            for _, item in ipairs(sorted) do
                local v = item.value
                local y = margin + plot_height - (v - global_min) / (global_max - global_min) * plot_height

                -- Find x offset that doesn't overlap with nearby points
                local x_offset = 0
                local found = false

                for attempt = 0, 20 do
                    local test_offset = (attempt % 2 == 0 and 1 or -1) * math.floor((attempt + 1) / 2) * point_radius * 2.2

                    local overlap = false
                    for _, p in ipairs(placed) do
                        local dy = math.abs(p.y - y)
                        local dx = math.abs(p.x_offset - test_offset)
                        if math.sqrt(dy * dy + dx * dx) < point_radius * 2.2 then
                            overlap = true
                            break
                        end
                    end

                    if not overlap and math.abs(test_offset) <= max_width then
                        x_offset = test_offset
                        found = true
                        break
                    end
                end

                if not found then x_offset = 0 end

                table.insert(placed, {y = y, x_offset = x_offset})

                if orient == "v" then
                    ctx:circle(base_x + x_offset, y, point_radius)
                else
                    ctx:circle(y, base_x + x_offset, point_radius)
                end
                ctx:fill()
            end
        end

        return ax
    end

    -- regplot (matches seaborn sns.regplot)
    function stat.regplot(ax, x_data, y_data, opts)
        opts = opts or {}
        local ci = opts.ci or 95
        local color = opts.color or "steelblue"
        local scatter = opts.scatter
        if scatter == nil then scatter = true end
        local fit_reg = opts.fit_reg
        if fit_reg == nil then fit_reg = true end
        local order = opts.order or 1
        local marker = opts.marker or "o"
        local scatter_kws = opts.scatter_kws or {}
        local line_kws = opts.line_kws or {}

        local ctx = ax:get_context()
        local margin = 50
        local plot_width = ax._figure._width - 2 * margin
        local plot_height = ax._figure._height - 2 * margin

        local n = #x_data

        -- Find data ranges
        local xmin, xmax = x_data[1], x_data[1]
        local ymin, ymax = y_data[1], y_data[1]
        for i = 1, n do
            if x_data[i] < xmin then xmin = x_data[i] end
            if x_data[i] > xmax then xmax = x_data[i] end
            if y_data[i] < ymin then ymin = y_data[i] end
            if y_data[i] > ymax then ymax = y_data[i] end
        end
        if xmax == xmin then xmax = xmin + 1 end
        if ymax == ymin then ymax = ymin + 1 end

        -- Draw scatter points
        if scatter then
            local sc_color = scatter_kws.color or color
            local sc_size = scatter_kws.s or 30
            ctx:set_fill(sc_color)
            for i = 1, n do
                local px = margin + (x_data[i] - xmin) / (xmax - xmin) * plot_width
                local py = margin + plot_height - (y_data[i] - ymin) / (ymax - ymin) * plot_height
                ctx:circle(px, py, math.sqrt(sc_size / math.pi))
                ctx:fill()
            end
        end

        -- Linear regression
        if fit_reg then
            -- Calculate slope and intercept (simple linear regression)
            local sum_x, sum_y, sum_xy, sum_xx = 0, 0, 0, 0
            for i = 1, n do
                sum_x = sum_x + x_data[i]
                sum_y = sum_y + y_data[i]
                sum_xy = sum_xy + x_data[i] * y_data[i]
                sum_xx = sum_xx + x_data[i] * x_data[i]
            end

            local slope = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x)
            local intercept = (sum_y - slope * sum_x) / n

            -- Draw regression line
            local line_color = line_kws.color or color
            local line_width = line_kws.linewidth or 2

            ctx:set_stroke(line_color, line_width)

            local y1 = slope * xmin + intercept
            local y2 = slope * xmax + intercept

            local px1 = margin
            local py1 = margin + plot_height - (y1 - ymin) / (ymax - ymin) * plot_height
            local px2 = margin + plot_width
            local py2 = margin + plot_height - (y2 - ymin) / (ymax - ymin) * plot_height

            ctx:move_to(px1, py1)
            ctx:line_to(px2, py2)
            ctx:stroke()

            -- Confidence interval band (simplified - using standard error)
            if ci then
                -- Calculate residual standard error
                local ss_res = 0
                for i = 1, n do
                    local predicted = slope * x_data[i] + intercept
                    ss_res = ss_res + (y_data[i] - predicted)^2
                end
                local se = math.sqrt(ss_res / (n - 2))

                -- Simple CI band (approximation)
                local t_val = 1.96  -- approximate for 95% CI

                ctx:set_fill(line_color)
                -- Draw filled region (simplified as parallel lines)
                local band_width = t_val * se * 2

                ctx:move_to(margin, py1 - band_width / (ymax - ymin) * plot_height)
                ctx:line_to(margin + plot_width, py2 - band_width / (ymax - ymin) * plot_height)
                ctx:line_to(margin + plot_width, py2 + band_width / (ymax - ymin) * plot_height)
                ctx:line_to(margin, py1 + band_width / (ymax - ymin) * plot_height)
                ctx:close_path()
                ctx:fill()

                -- Redraw line on top
                ctx:set_stroke(line_color, line_width)
                ctx:move_to(px1, py1)
                ctx:line_to(px2, py2)
                ctx:stroke()
            end
        end

        return ax
    end

    -- heatmap (matches seaborn sns.heatmap) - delegates to imshow with annotations
    function stat.heatmap(ax, data, opts)
        opts = opts or {}
        local annot = opts.annot or false
        local fmt = opts.fmt or "%.2g"
        local cmap = opts.cmap or "viridis"
        local center = opts.center
        local vmin = opts.vmin
        local vmax = opts.vmax
        local linewidths = opts.linewidths or 0
        local linecolor = opts.linecolor or "white"
        local square = opts.square or false
        local cbar = opts.cbar
        if cbar == nil then cbar = true end
        local xticklabels = opts.xticklabels
        local yticklabels = opts.yticklabels

        -- Convert Python-style format string to Lua format string
        -- e.g., ".2f" -> "%.2f", "d" -> "%d"
        if fmt:sub(1, 1) ~= "%" then
            fmt = "%" .. fmt
        end

        -- Use imshow for the base heatmap
        ax:imshow(data, {cmap = cmap, vmin = vmin, vmax = vmax})

        local ctx = ax:get_context()
        local margin = 50
        local plot_width = ax._figure._width - 2 * margin
        local plot_height = ax._figure._height - 2 * margin

        local nrows = #data
        local ncols = #data[1]

        local cell_width = plot_width / ncols
        local cell_height = plot_height / nrows

        -- Add annotations if requested
        if annot then
            for i = 1, nrows do
                for j = 1, ncols do
                    local v = data[i][j]
                    local label = string.format(fmt, v)

                    local x = margin + (j - 0.5) * cell_width
                    local y = margin + (nrows - i + 0.5) * cell_height

                    -- Choose contrasting text color
                    local text_color = "white"
                    if v and vmin and vmax then
                        local t = (v - (vmin or 0)) / ((vmax or 1) - (vmin or 0))
                        if t > 0.5 then text_color = "black" end
                    end

                    ctx:text(label, x, y, {
                        anchor = "middle",
                        fontSize = 10,
                        color = text_color
                    })
                end
            end
        end

        -- Add x-axis tick labels
        if xticklabels then
            for j, label in ipairs(xticklabels) do
                local x = margin + (j - 0.5) * cell_width
                local y = margin + plot_height + 15
                ctx:text(tostring(label), x, y, {
                    anchor = "middle",
                    fontSize = 10,
                    color = "black"
                })
            end
        end

        -- Add y-axis tick labels
        if yticklabels then
            for i, label in ipairs(yticklabels) do
                local x = margin - 10
                local y = margin + (nrows - i + 0.5) * cell_height
                ctx:text(tostring(label), x, y, {
                    anchor = "end",
                    fontSize = 10,
                    color = "black"
                })
            end
        end

        -- Add cell borders
        if linewidths > 0 then
            ctx:set_stroke(linecolor, linewidths)

            for i = 0, nrows do
                local y = margin + i * cell_height
                ctx:move_to(margin, y)
                ctx:line_to(margin + plot_width, y)
            end

            for j = 0, ncols do
                local x = margin + j * cell_width
                ctx:move_to(x, margin)
                ctx:line_to(x, margin + plot_height)
            end
            ctx:stroke()
        end

        return ax
    end

    -- Make stat namespace available
    package.loaded["luaswift.plot.stat"] = stat

    -- Make available via require
    package.loaded["luaswift.plot"] = plot

    -- Top-level alias
    plt = plot

    -- Clean up temporary globals
    _luaswift_plot_create_context = nil
    _luaswift_plot_destroy_context = nil
    _luaswift_plot_clear_context = nil
    _luaswift_plot_command_count = nil
    _luaswift_plot_move_to = nil
    _luaswift_plot_line_to = nil
    _luaswift_plot_curve_to = nil
    _luaswift_plot_close_path = nil
    _luaswift_plot_rect = nil
    _luaswift_plot_ellipse = nil
    _luaswift_plot_circle = nil
    _luaswift_plot_text = nil
    _luaswift_plot_set_stroke = nil
    _luaswift_plot_set_fill = nil
    _luaswift_plot_stroke = nil
    _luaswift_plot_fill = nil
    _luaswift_plot_save = nil
    _luaswift_plot_restore = nil
    _luaswift_plot_to_svg = nil
    _luaswift_plot_to_png = nil
    _luaswift_plot_to_pdf = nil
    _luaswift_plot_savefig = nil
    """
}
