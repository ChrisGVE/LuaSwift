//
//  ProblemController.swift
//  LuaSwift
//
//  Created by Christian C. Berclaz on 2026-01-04.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import Foundation

// MARK: - Input Type

/// Represents the type of input expected from the user.
public enum InputType: Equatable, Sendable {
    /// Numeric input (integer or decimal)
    case numeric
    /// Free-form text input
    case text
    /// Multiple choice selection
    case multipleChoice(options: [String])
}

// MARK: - Problem State

/// Represents the current state of the problem flow.
public enum ProblemState: Equatable, Sendable {
    /// Problem is being loaded
    case loading
    /// Problem is being presented to the user
    case presenting
    /// Waiting for user input
    case waitingForAnswer(inputType: InputType)
    /// Evaluating the user's answer
    case evaluating
    /// Problem completed successfully
    case complete(result: ProblemResult)
    /// An error occurred
    case error(String)

    public static func == (lhs: ProblemState, rhs: ProblemState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
             (.presenting, .presenting),
             (.evaluating, .evaluating):
            return true
        case (.waitingForAnswer(let lType), .waitingForAnswer(let rType)):
            return lType == rType
        case (.complete(let lResult), .complete(let rResult)):
            return lResult == rResult
        case (.error(let lMsg), .error(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

// MARK: - Hint Type

/// Represents the type of hint to provide.
public enum HintType: String, Equatable, Sendable, CaseIterable {
    /// Symbolic equation hint (e.g., "Solve using: n1*sin(theta1) = n2*sin(theta2)")
    case symbolic
    /// Step-by-step numerical calculation hint
    case numerical
    /// Hint optimized for slide rule operations
    case slideRule

    /// Human-readable description of the hint type
    public var description: String {
        switch self {
        case .symbolic:
            return "Symbolic equation hint"
        case .numerical:
            return "Step-by-step calculation"
        case .slideRule:
            return "Slide rule optimization"
        }
    }
}

// MARK: - Hint

/// Represents a hint provided to the user.
public struct Hint: Equatable, Sendable {
    /// The type of hint
    public let type: HintType
    /// The main hint content
    public let content: String
    /// Optional step-by-step breakdown (for numerical hints)
    public let steps: [String]?
    /// Optional symbolic equation form
    public let equation: String?
    /// Optional SVG diagram
    public let svgDiagram: String?

    /// Create a hint with all properties
    public init(type: HintType, content: String, steps: [String]? = nil, equation: String? = nil, svgDiagram: String? = nil) {
        self.type = type
        self.content = content
        self.steps = steps
        self.equation = equation
        self.svgDiagram = svgDiagram
    }

    /// Create a symbolic hint
    public static func symbolic(_ content: String, equation: String? = nil) -> Hint {
        Hint(type: .symbolic, content: content, equation: equation)
    }

    /// Create a numerical step-by-step hint
    public static func numerical(_ content: String, steps: [String]) -> Hint {
        Hint(type: .numerical, content: content, steps: steps)
    }

    /// Create a slide rule hint
    public static func slideRule(_ content: String, svgDiagram: String? = nil) -> Hint {
        Hint(type: .slideRule, content: content, svgDiagram: svgDiagram)
    }
}

// MARK: - Answer Result

/// Represents the result of evaluating a user's answer.
public enum AnswerResult: Equatable, Sendable {
    /// The answer is correct
    case correct(feedback: String?)
    /// The answer is incorrect
    case incorrect(feedback: String, correctAnswer: LuaValue?)
    /// The answer is partially correct
    case partiallyCorrect(score: Double, feedback: String)
    /// An error occurred during evaluation
    case error(String)

    /// Whether the answer was correct
    public var isCorrect: Bool {
        if case .correct = self { return true }
        return false
    }

    /// The score for this answer (1.0 for correct, 0.0-1.0 for partial, 0.0 for incorrect)
    public var score: Double {
        switch self {
        case .correct:
            return 1.0
        case .incorrect:
            return 0.0
        case .partiallyCorrect(let score, _):
            return score
        case .error:
            return 0.0
        }
    }

    public static func == (lhs: AnswerResult, rhs: AnswerResult) -> Bool {
        switch (lhs, rhs) {
        case (.correct(let lFeedback), .correct(let rFeedback)):
            return lFeedback == rFeedback
        case (.incorrect(let lFeedback, let lAnswer), .incorrect(let rFeedback, let rAnswer)):
            return lFeedback == rFeedback && lAnswer == rAnswer
        case (.partiallyCorrect(let lScore, let lFeedback), .partiallyCorrect(let rScore, let rFeedback)):
            return lScore == rScore && lFeedback == rFeedback
        case (.error(let lMsg), .error(let rMsg)):
            return lMsg == rMsg
        default:
            return false
        }
    }
}

// MARK: - Problem Result

/// Represents the final result of a completed problem.
public struct ProblemResult: Equatable, Sendable {
    /// The user's final answer (if provided)
    public let finalAnswer: LuaValue?
    /// The result of evaluating the final answer
    public let answerResult: AnswerResult?
    /// Number of attempts made
    public let attemptCount: Int
    /// Hints that were used
    public let hintsUsed: [HintType]
    /// Time elapsed from start to completion
    public let timeElapsed: TimeInterval
    /// Whether the problem was completed (answered correctly)
    public let completed: Bool
    /// Whether the problem was skipped
    public let skipped: Bool

    /// Create a problem result
    public init(
        finalAnswer: LuaValue? = nil,
        answerResult: AnswerResult? = nil,
        attemptCount: Int = 0,
        hintsUsed: [HintType] = [],
        timeElapsed: TimeInterval = 0,
        completed: Bool = false,
        skipped: Bool = false
    ) {
        self.finalAnswer = finalAnswer
        self.answerResult = answerResult
        self.attemptCount = attemptCount
        self.hintsUsed = hintsUsed
        self.timeElapsed = timeElapsed
        self.completed = completed
        self.skipped = skipped
    }

    /// Success rate based on answer result
    public var successRate: Double {
        answerResult?.score ?? 0.0
    }

    /// Whether any hints were used
    public var usedHints: Bool {
        !hintsUsed.isEmpty
    }
}

// MARK: - Problem

/// Represents a loaded problem with its metadata and validation functions.
public struct Problem: Sendable {
    /// Unique identifier for the problem
    public let id: String
    /// Display title
    public let title: String
    /// Question content in markdown format
    public let questionMarkdown: String
    /// Optional SVG diagram
    public let svgDiagram: String?
    /// Expected input type
    public let inputType: InputType
    /// Name of the Lua validation function
    public let validationFunctionName: String
    /// Mapping of hint types to Lua function names
    public let hints: [HintType: String]
    /// Additional metadata from Lua
    public let metadata: [String: LuaValue]

    /// Create a problem
    public init(
        id: String,
        title: String,
        questionMarkdown: String,
        svgDiagram: String? = nil,
        inputType: InputType = .numeric,
        validationFunctionName: String = "validate",
        hints: [HintType: String] = [:],
        metadata: [String: LuaValue] = [:]
    ) {
        self.id = id
        self.title = title
        self.questionMarkdown = questionMarkdown
        self.svgDiagram = svgDiagram
        self.inputType = inputType
        self.validationFunctionName = validationFunctionName
        self.hints = hints
        self.metadata = metadata
    }
}

// MARK: - Problem Controller Delegate

/// Delegate protocol for receiving problem controller events.
public protocol ProblemControllerDelegate: AnyObject {
    /// Called to display markdown content
    func displayMarkdown(_ content: String)

    /// Called to display an SVG diagram
    func displaySVG(_ svgString: String)

    /// Called when the problem is completed
    func problemCompleted(result: ProblemResult)

    /// Called when the state changes
    func stateChanged(from oldState: ProblemState, to newState: ProblemState)

    /// Called when user input is requested
    func inputRequested(type: InputType)

    /// Called when a hint is displayed
    func hintDisplayed(_ hint: Hint)
}

// MARK: - Problem Controller Error

/// Errors that can occur during problem control.
public enum ProblemControllerError: Error, Equatable {
    /// Invalid state transition attempted
    case invalidStateTransition(from: String, to: String)
    /// No problem is currently loaded
    case noProblemLoaded
    /// Problem is already completed
    case problemAlreadyCompleted
    /// Invalid answer format
    case invalidAnswerFormat(expected: String)
    /// Hint not available
    case hintNotAvailable(HintType)
    /// Lua evaluation error
    case luaError(String)
}

// MARK: - Problem Controller

/// Controller for orchestrating problem flow: loading, interaction, hints, and completion.
///
/// `ProblemController` manages the lifecycle of educational problems, handling:
/// - Loading problem Lua code and context
/// - User input and answer validation
/// - Hint requests
/// - State machine transitions
///
/// ## Usage
///
/// ```swift
/// let engine = try LuaEngine()
/// let controller = ProblemController(engine: engine)
/// controller.delegate = self
///
/// // Load a problem
/// let problem = try controller.loadProblem(luaCode: problemScript, context: ["wavelength": .number(550)])
///
/// // Submit an answer
/// let result = try controller.submitAnswer(.number(42))
///
/// // Request a hint
/// let hint = try controller.requestHint(type: .symbolic)
/// ```
public class ProblemController {

    // MARK: - Properties

    /// The Lua engine used for execution
    private let engine: LuaEngine

    /// Lock for thread safety
    private let lock = NSLock()

    /// Delegate for UI callbacks
    public weak var delegate: ProblemControllerDelegate?

    /// Current state of the problem flow
    public private(set) var currentState: ProblemState = .loading

    /// Currently loaded problem
    public private(set) var currentProblem: Problem?

    /// Current coroutine handle
    private var currentCoroutine: CoroutineHandle?

    // MARK: - Session Tracking

    /// Number of answer attempts
    private var attemptCount: Int = 0

    /// Hints that have been used
    private var hintsUsed: [HintType] = []

    /// Session start time
    private var sessionStartTime: Date?

    /// Last answer submission time
    private var lastAnswerTime: Date?

    // MARK: - Initialization

    /// Create a new problem controller with the given Lua engine.
    /// - Parameter engine: The Lua engine to use for problem execution
    public init(engine: LuaEngine) {
        self.engine = engine
        registerCallbacks()
    }

    deinit {
        reset()
    }

    // MARK: - Public Methods

    /// Load a problem from Lua code.
    /// - Parameters:
    ///   - luaCode: The Lua code defining the problem
    ///   - context: Optional context values to pass to the problem
    /// - Returns: The loaded problem
    /// - Throws: `ProblemControllerError` if loading fails
    public func loadProblem(luaCode: String, context: [String: LuaValue] = [:]) throws -> Problem {
        lock.lock()
        defer { lock.unlock() }

        // Reset any previous session
        resetSession()

        // Register context server if we have context
        if !context.isEmpty {
            let contextServer = ProblemContextServer(context: context)
            engine.register(server: contextServer)
        }

        // Create coroutine for the problem
        currentCoroutine = try engine.createCoroutine(code: luaCode)

        // Resume to get problem metadata
        let result = try engine.resume(currentCoroutine!)

        // Parse problem from first yield
        let problem = try parseProblem(from: result)
        currentProblem = problem

        // Start session tracking
        startSession()

        // Transition to presenting state
        try transition(to: .presenting)

        return problem
    }

    /// Submit an answer to the current problem.
    /// - Parameter answer: The user's answer
    /// - Returns: The result of evaluating the answer
    /// - Throws: `ProblemControllerError` if submission fails
    public func submitAnswer(_ answer: LuaValue) throws -> AnswerResult {
        lock.lock()
        defer { lock.unlock() }

        guard currentProblem != nil else {
            throw ProblemControllerError.noProblemLoaded
        }

        guard case .waitingForAnswer = currentState else {
            if case .complete = currentState {
                throw ProblemControllerError.problemAlreadyCompleted
            }
            throw ProblemControllerError.invalidStateTransition(
                from: stateDescription(currentState),
                to: "evaluating"
            )
        }

        // Transition to evaluating
        try transition(to: .evaluating)

        // Record attempt
        recordAttempt()

        // Resume coroutine with answer
        guard let coroutine = currentCoroutine else {
            throw ProblemControllerError.noProblemLoaded
        }

        let result = try engine.resume(coroutine, with: [answer])

        // Parse answer result
        let answerResult = try parseAnswerResult(from: result)

        // Handle result
        if answerResult.isCorrect {
            let problemResult = endSession(answer: answer, result: answerResult)
            try transition(to: .complete(result: problemResult))
        } else {
            // Allow another attempt
            let inputType = currentProblem?.inputType ?? .numeric
            try transition(to: .waitingForAnswer(inputType: inputType))
        }

        return answerResult
    }

    /// Request a hint of the specified type.
    /// - Parameter type: The type of hint to request
    /// - Returns: The generated hint
    /// - Throws: `ProblemControllerError` if hint is not available
    public func requestHint(type: HintType) throws -> Hint {
        lock.lock()
        defer { lock.unlock() }

        guard let problem = currentProblem else {
            throw ProblemControllerError.noProblemLoaded
        }

        // Check if this hint type is available
        guard let hintFunctionName = problem.hints[type] else {
            throw ProblemControllerError.hintNotAvailable(type)
        }

        // Call the hint function
        let result = try engine.evaluate("return \(hintFunctionName)()")

        // Parse hint
        let hint = try parseHint(from: result, type: type)

        // Record hint usage
        recordHint(type)

        // Notify delegate
        delegate?.hintDisplayed(hint)

        return hint
    }

    /// Skip the current problem.
    /// - Throws: `ProblemControllerError` if skip fails
    public func skipProblem() throws {
        lock.lock()
        defer { lock.unlock() }

        guard currentProblem != nil else {
            throw ProblemControllerError.noProblemLoaded
        }

        if case .complete = currentState {
            throw ProblemControllerError.problemAlreadyCompleted
        }

        // Destroy coroutine if active
        if let coroutine = currentCoroutine {
            engine.destroy(coroutine)
            currentCoroutine = nil
        }

        // Create skip result
        let result = ProblemResult(
            attemptCount: attemptCount,
            hintsUsed: hintsUsed,
            timeElapsed: sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0,
            completed: false,
            skipped: true
        )

        // Transition to complete
        try transition(to: .complete(result: result))

        // Notify delegate
        delegate?.problemCompleted(result: result)
    }

    /// Reset the controller for a new problem.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }

        // Destroy coroutine if active
        if let coroutine = currentCoroutine {
            engine.destroy(coroutine)
            currentCoroutine = nil
        }

        // Reset state
        currentProblem = nil
        currentState = .loading
        resetSession()

        // Unregister callbacks
        unregisterCallbacks()
    }

    // MARK: - Private Methods

    private func registerCallbacks() {
        // Register renderMarkdown callback
        engine.registerFunction(name: "renderMarkdown") { [weak self] args in
            if let content = args.first?.stringValue {
                DispatchQueue.main.async {
                    self?.delegate?.displayMarkdown(content)
                }
            }
            return .nil
        }

        // Register displaySVG callback
        engine.registerFunction(name: "displaySVG") { [weak self] args in
            guard let svgString = args.first?.stringValue else {
                return .bool(false)
            }

            // Basic validation
            guard svgString.contains("<svg") else {
                return .bool(false)
            }

            DispatchQueue.main.async {
                self?.delegate?.displaySVG(svgString)
            }
            return .bool(true)
        }

        // Register waitForInput callback
        engine.registerFunction(name: "waitForInput") { [weak self] args in
            let inputTypeString = args.first?.stringValue ?? "numeric"
            let inputType: InputType

            switch inputTypeString {
            case "text":
                inputType = .text
            case "numeric":
                inputType = .numeric
            default:
                if inputTypeString.hasPrefix("choice:") {
                    let optionsString = String(inputTypeString.dropFirst(7))
                    let options = optionsString.split(separator: ",").map(String.init)
                    inputType = .multipleChoice(options: options)
                } else {
                    inputType = .numeric
                }
            }

            DispatchQueue.main.async {
                self?.delegate?.inputRequested(type: inputType)
            }

            // Return marker for coroutine yield
            return .string("__WAIT_FOR_INPUT__")
        }
    }

    private func unregisterCallbacks() {
        engine.unregisterFunction(name: "renderMarkdown")
        engine.unregisterFunction(name: "displaySVG")
        engine.unregisterFunction(name: "waitForInput")
    }

    private func transition(to newState: ProblemState) throws {
        let oldState = currentState

        // Validate transition
        guard isValidTransition(from: oldState, to: newState) else {
            throw ProblemControllerError.invalidStateTransition(
                from: stateDescription(oldState),
                to: stateDescription(newState)
            )
        }

        // Notify delegate before updating
        delegate?.stateChanged(from: oldState, to: newState)

        // Update state
        currentState = newState
    }

    private func isValidTransition(from: ProblemState, to: ProblemState) -> Bool {
        switch (from, to) {
        case (.loading, .presenting):
            return true
        case (.presenting, .waitingForAnswer):
            return true
        case (.waitingForAnswer, .evaluating):
            return true
        case (.evaluating, .complete):
            return true
        case (.evaluating, .waitingForAnswer):
            return true // Allow retry
        case (_, .error):
            return true // Can always go to error
        case (.waitingForAnswer, .complete):
            return true // For skipping
        case (.presenting, .complete):
            return true // For skipping before input
        default:
            return false
        }
    }

    private func stateDescription(_ state: ProblemState) -> String {
        switch state {
        case .loading: return "loading"
        case .presenting: return "presenting"
        case .waitingForAnswer: return "waitingForAnswer"
        case .evaluating: return "evaluating"
        case .complete: return "complete"
        case .error: return "error"
        }
    }

    private func parseProblem(from result: CoroutineResult) throws -> Problem {
        // For now, create a basic problem from the result
        // This will be expanded based on actual Lua problem format
        guard case .yielded(let values) = result,
              let table = values.first?.tableValue else {
            throw ProblemControllerError.luaError("Expected problem metadata table from yield")
        }

        let id = table["id"]?.stringValue ?? UUID().uuidString
        let title = table["title"]?.stringValue ?? "Problem"
        let question = table["question"]?.stringValue ?? ""
        let svg = table["svg"]?.stringValue

        // Parse input type
        var inputType: InputType = .numeric
        if let inputTypeStr = table["inputType"]?.stringValue {
            switch inputTypeStr {
            case "text": inputType = .text
            case "numeric": inputType = .numeric
            default:
                if inputTypeStr.hasPrefix("choice:") {
                    let options = String(inputTypeStr.dropFirst(7)).split(separator: ",").map(String.init)
                    inputType = .multipleChoice(options: options)
                }
            }
        }

        // Parse hints
        var hints: [HintType: String] = [:]
        if let hintsTable = table["hints"]?.tableValue {
            if let symbolic = hintsTable["symbolic"]?.stringValue {
                hints[.symbolic] = symbolic
            }
            if let numerical = hintsTable["numerical"]?.stringValue {
                hints[.numerical] = numerical
            }
            if let slideRule = hintsTable["slideRule"]?.stringValue {
                hints[.slideRule] = slideRule
            }
        }

        return Problem(
            id: id,
            title: title,
            questionMarkdown: question,
            svgDiagram: svg,
            inputType: inputType,
            validationFunctionName: table["validate"]?.stringValue ?? "validate",
            hints: hints,
            metadata: table
        )
    }

    private func parseAnswerResult(from result: CoroutineResult) throws -> AnswerResult {
        switch result {
        case .completed(let value):
            // Problem completed after answer
            if let table = value.tableValue {
                return parseAnswerResultFromTable(table)
            }
            return .correct(feedback: nil)

        case .yielded(let values):
            // More interaction needed
            if let table = values.first?.tableValue {
                return parseAnswerResultFromTable(table)
            }
            return .incorrect(feedback: "Try again", correctAnswer: nil)

        case .error(let error):
            throw ProblemControllerError.luaError(error.localizedDescription)
        }
    }

    private func parseAnswerResultFromTable(_ table: [String: LuaValue]) -> AnswerResult {
        let isCorrect = table["correct"]?.boolValue ?? false
        let feedback = table["feedback"]?.stringValue

        if isCorrect {
            return .correct(feedback: feedback)
        } else {
            let correctAnswer = table["answer"]
            return .incorrect(feedback: feedback ?? "Incorrect", correctAnswer: correctAnswer)
        }
    }

    private func parseHint(from result: LuaValue, type: HintType) throws -> Hint {
        if let content = result.stringValue {
            return Hint(type: type, content: content)
        }

        if let table = result.tableValue {
            let content = table["content"]?.stringValue ?? ""
            let steps = table["steps"]?.arrayValue?.compactMap { $0.stringValue }
            let equation = table["equation"]?.stringValue
            let svg = table["svg"]?.stringValue

            return Hint(type: type, content: content, steps: steps, equation: equation, svgDiagram: svg)
        }

        throw ProblemControllerError.luaError("Invalid hint format returned from Lua")
    }

    // MARK: - Session Tracking

    private func startSession() {
        sessionStartTime = Date()
        attemptCount = 0
        hintsUsed = []
    }

    private func resetSession() {
        sessionStartTime = nil
        lastAnswerTime = nil
        attemptCount = 0
        hintsUsed = []
    }

    private func recordAttempt() {
        attemptCount += 1
        lastAnswerTime = Date()
    }

    private func recordHint(_ type: HintType) {
        if !hintsUsed.contains(type) {
            hintsUsed.append(type)
        }
    }

    private func endSession(answer: LuaValue, result: AnswerResult) -> ProblemResult {
        let elapsed = sessionStartTime.map { Date().timeIntervalSince($0) } ?? 0

        return ProblemResult(
            finalAnswer: answer,
            answerResult: result,
            attemptCount: attemptCount,
            hintsUsed: hintsUsed,
            timeElapsed: elapsed,
            completed: result.isCorrect,
            skipped: false
        )
    }
}

// MARK: - Problem Context Server

/// LuaValueServer for providing problem context to Lua scripts.
private class ProblemContextServer: LuaValueServer {
    let namespace = "Problem"
    private let context: [String: LuaValue]

    init(context: [String: LuaValue]) {
        self.context = context
    }

    func resolve(path: [String]) -> LuaValue {
        guard let key = path.first else {
            return .nil
        }

        if path.count == 1 {
            return context[key] ?? .nil
        }

        // Handle nested paths
        var current = context[key]
        for pathComponent in path.dropFirst() {
            guard let table = current?.tableValue else {
                return .nil
            }
            current = table[pathComponent]
        }

        return current ?? .nil
    }
}
