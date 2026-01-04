//
//  ProblemControllerTests.swift
//  LuaSwiftTests
//
//  Created by Christian C. Berclaz on 2026-01-04.
//  Copyright © 2026 Christian C. Berclaz. All rights reserved.
//
//  Licensed under the MIT License.
//

import XCTest
@testable import LuaSwift

// MARK: - Mock Delegate

class MockProblemControllerDelegate: ProblemControllerDelegate {
    var displayedMarkdown: [String] = []
    var displayedSVGs: [String] = []
    var completedResults: [ProblemResult] = []
    var stateChanges: [(from: ProblemState, to: ProblemState)] = []
    var inputRequests: [InputType] = []
    var displayedHints: [Hint] = []

    func displayMarkdown(_ content: String) {
        displayedMarkdown.append(content)
    }

    func displaySVG(_ svgString: String) {
        displayedSVGs.append(svgString)
    }

    func problemCompleted(result: ProblemResult) {
        completedResults.append(result)
    }

    func stateChanged(from oldState: ProblemState, to newState: ProblemState) {
        stateChanges.append((from: oldState, to: newState))
    }

    func inputRequested(type: InputType) {
        inputRequests.append(type)
    }

    func hintDisplayed(_ hint: Hint) {
        displayedHints.append(hint)
    }

    func reset() {
        displayedMarkdown = []
        displayedSVGs = []
        completedResults = []
        stateChanges = []
        inputRequests = []
        displayedHints = []
    }
}

// MARK: - Problem State Tests

final class ProblemStateTests: XCTestCase {

    func testProblemStateEquality() {
        XCTAssertEqual(ProblemState.loading, ProblemState.loading)
        XCTAssertEqual(ProblemState.presenting, ProblemState.presenting)
        XCTAssertEqual(ProblemState.evaluating, ProblemState.evaluating)
        XCTAssertNotEqual(ProblemState.loading, ProblemState.presenting)
    }

    func testProblemStateWaitingForAnswerEquality() {
        let state1 = ProblemState.waitingForAnswer(inputType: .numeric)
        let state2 = ProblemState.waitingForAnswer(inputType: .numeric)
        let state3 = ProblemState.waitingForAnswer(inputType: .text)

        XCTAssertEqual(state1, state2)
        XCTAssertNotEqual(state1, state3)
    }

    func testProblemStateErrorEquality() {
        let state1 = ProblemState.error("Error 1")
        let state2 = ProblemState.error("Error 1")
        let state3 = ProblemState.error("Error 2")

        XCTAssertEqual(state1, state2)
        XCTAssertNotEqual(state1, state3)
    }
}

// MARK: - Hint Type Tests

final class HintTypeTests: XCTestCase {

    func testHintTypeDescription() {
        XCTAssertEqual(HintType.symbolic.description, "Symbolic equation hint")
        XCTAssertEqual(HintType.numerical.description, "Step-by-step calculation")
        XCTAssertEqual(HintType.slideRule.description, "Slide rule optimization")
    }

    func testHintTypeCaseIterable() {
        XCTAssertEqual(HintType.allCases.count, 3)
        XCTAssertTrue(HintType.allCases.contains(.symbolic))
        XCTAssertTrue(HintType.allCases.contains(.numerical))
        XCTAssertTrue(HintType.allCases.contains(.slideRule))
    }

    func testHintTypeRawValue() {
        XCTAssertEqual(HintType.symbolic.rawValue, "symbolic")
        XCTAssertEqual(HintType.numerical.rawValue, "numerical")
        XCTAssertEqual(HintType.slideRule.rawValue, "slideRule")
    }
}

// MARK: - Hint Tests

final class HintTests: XCTestCase {

    func testHintInitialization() {
        let hint = Hint(type: .symbolic, content: "Use the formula", equation: "E = mc^2")

        XCTAssertEqual(hint.type, .symbolic)
        XCTAssertEqual(hint.content, "Use the formula")
        XCTAssertEqual(hint.equation, "E = mc^2")
        XCTAssertNil(hint.steps)
        XCTAssertNil(hint.svgDiagram)
    }

    func testSymbolicHintFactory() {
        let hint = Hint.symbolic("Use this equation", equation: "a^2 + b^2 = c^2")

        XCTAssertEqual(hint.type, .symbolic)
        XCTAssertEqual(hint.content, "Use this equation")
        XCTAssertEqual(hint.equation, "a^2 + b^2 = c^2")
    }

    func testNumericalHintFactory() {
        let steps = ["Step 1: Calculate A", "Step 2: Calculate B", "Step 3: Add them"]
        let hint = Hint.numerical("Follow these steps", steps: steps)

        XCTAssertEqual(hint.type, .numerical)
        XCTAssertEqual(hint.content, "Follow these steps")
        XCTAssertEqual(hint.steps, steps)
    }

    func testSlideRuleHintFactory() {
        let hint = Hint.slideRule("Use C and D scales", svgDiagram: "<svg></svg>")

        XCTAssertEqual(hint.type, .slideRule)
        XCTAssertEqual(hint.content, "Use C and D scales")
        XCTAssertEqual(hint.svgDiagram, "<svg></svg>")
    }
}

// MARK: - Answer Result Tests

final class AnswerResultTests: XCTestCase {

    func testCorrectAnswerResult() {
        let result = AnswerResult.correct(feedback: "Great job!")

        XCTAssertTrue(result.isCorrect)
        XCTAssertEqual(result.score, 1.0)
    }

    func testIncorrectAnswerResult() {
        let result = AnswerResult.incorrect(feedback: "Try again", correctAnswer: .number(42))

        XCTAssertFalse(result.isCorrect)
        XCTAssertEqual(result.score, 0.0)
    }

    func testPartiallyCorrectAnswerResult() {
        let result = AnswerResult.partiallyCorrect(score: 0.75, feedback: "Almost!")

        XCTAssertFalse(result.isCorrect)
        XCTAssertEqual(result.score, 0.75)
    }

    func testErrorAnswerResult() {
        let result = AnswerResult.error("Evaluation failed")

        XCTAssertFalse(result.isCorrect)
        XCTAssertEqual(result.score, 0.0)
    }

    func testAnswerResultEquality() {
        let result1 = AnswerResult.correct(feedback: "Yes!")
        let result2 = AnswerResult.correct(feedback: "Yes!")
        let result3 = AnswerResult.correct(feedback: "Good!")

        XCTAssertEqual(result1, result2)
        XCTAssertNotEqual(result1, result3)
    }
}

// MARK: - Problem Result Tests

final class ProblemResultTests: XCTestCase {

    func testProblemResultInitialization() {
        let result = ProblemResult(
            finalAnswer: .number(42),
            answerResult: .correct(feedback: nil),
            attemptCount: 2,
            hintsUsed: [.symbolic],
            timeElapsed: 60.0,
            completed: true,
            skipped: false
        )

        XCTAssertEqual(result.finalAnswer, .number(42))
        XCTAssertEqual(result.attemptCount, 2)
        XCTAssertEqual(result.hintsUsed, [.symbolic])
        XCTAssertEqual(result.timeElapsed, 60.0)
        XCTAssertTrue(result.completed)
        XCTAssertFalse(result.skipped)
    }

    func testProblemResultSuccessRate() {
        let correctResult = ProblemResult(answerResult: .correct(feedback: nil))
        XCTAssertEqual(correctResult.successRate, 1.0)

        let partialResult = ProblemResult(answerResult: .partiallyCorrect(score: 0.5, feedback: ""))
        XCTAssertEqual(partialResult.successRate, 0.5)

        let incorrectResult = ProblemResult(answerResult: .incorrect(feedback: "", correctAnswer: nil))
        XCTAssertEqual(incorrectResult.successRate, 0.0)
    }

    func testProblemResultUsedHints() {
        let noHintsResult = ProblemResult(hintsUsed: [])
        XCTAssertFalse(noHintsResult.usedHints)

        let withHintsResult = ProblemResult(hintsUsed: [.symbolic, .numerical])
        XCTAssertTrue(withHintsResult.usedHints)
    }

    func testSkippedProblemResult() {
        let result = ProblemResult(
            attemptCount: 0,
            completed: false,
            skipped: true
        )

        XCTAssertNil(result.finalAnswer)
        XCTAssertTrue(result.skipped)
        XCTAssertFalse(result.completed)
    }
}

// MARK: - Problem Tests

final class ProblemTests: XCTestCase {

    func testProblemInitialization() {
        let problem = Problem(
            id: "prob-001",
            title: "Calculate Wavelength",
            questionMarkdown: "What is the wavelength?",
            svgDiagram: "<svg></svg>",
            inputType: .numeric,
            validationFunctionName: "validateAnswer",
            hints: [.symbolic: "getSymbolicHint"],
            metadata: ["difficulty": .number(3)]
        )

        XCTAssertEqual(problem.id, "prob-001")
        XCTAssertEqual(problem.title, "Calculate Wavelength")
        XCTAssertEqual(problem.questionMarkdown, "What is the wavelength?")
        XCTAssertEqual(problem.svgDiagram, "<svg></svg>")
        XCTAssertEqual(problem.inputType, .numeric)
        XCTAssertEqual(problem.validationFunctionName, "validateAnswer")
        XCTAssertEqual(problem.hints[.symbolic], "getSymbolicHint")
    }

    func testProblemDefaultValues() {
        let problem = Problem(
            id: "prob-002",
            title: "Simple Problem",
            questionMarkdown: "Answer this"
        )

        XCTAssertNil(problem.svgDiagram)
        XCTAssertEqual(problem.inputType, .numeric)
        XCTAssertEqual(problem.validationFunctionName, "validate")
        XCTAssertTrue(problem.hints.isEmpty)
    }
}

// MARK: - Input Type Tests

final class InputTypeTests: XCTestCase {

    func testInputTypeEquality() {
        XCTAssertEqual(InputType.numeric, InputType.numeric)
        XCTAssertEqual(InputType.text, InputType.text)
        XCTAssertNotEqual(InputType.numeric, InputType.text)
    }

    func testMultipleChoiceEquality() {
        let options1 = ["A", "B", "C"]
        let options2 = ["A", "B", "C"]
        let options3 = ["X", "Y", "Z"]

        XCTAssertEqual(InputType.multipleChoice(options: options1), InputType.multipleChoice(options: options2))
        XCTAssertNotEqual(InputType.multipleChoice(options: options1), InputType.multipleChoice(options: options3))
    }
}

// MARK: - Problem Controller Error Tests

final class ProblemControllerErrorTests: XCTestCase {

    func testErrorEquality() {
        let error1 = ProblemControllerError.noProblemLoaded
        let error2 = ProblemControllerError.noProblemLoaded
        let error3 = ProblemControllerError.problemAlreadyCompleted

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }

    func testInvalidStateTransitionError() {
        let error1 = ProblemControllerError.invalidStateTransition(from: "loading", to: "evaluating")
        let error2 = ProblemControllerError.invalidStateTransition(from: "loading", to: "evaluating")
        let error3 = ProblemControllerError.invalidStateTransition(from: "presenting", to: "loading")

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
}

// MARK: - Problem Controller Tests

final class ProblemControllerTests: XCTestCase {
    var engine: LuaEngine!
    var controller: ProblemController!
    var delegate: MockProblemControllerDelegate!

    override func setUp() {
        super.setUp()
        engine = try! LuaEngine()
        controller = ProblemController(engine: engine)
        delegate = MockProblemControllerDelegate()
        controller.delegate = delegate
    }

    override func tearDown() {
        controller.reset()
        controller = nil
        engine = nil
        delegate = nil
        super.tearDown()
    }

    func testControllerInitialState() {
        XCTAssertEqual(controller.currentState, .loading)
        XCTAssertNil(controller.currentProblem)
    }

    func testLoadProblem() throws {
        let luaCode = """
        coroutine.yield({
            id = "test-001",
            title = "Test Problem",
            question = "What is 2 + 2?",
            inputType = "numeric"
        })
        """

        let problem = try controller.loadProblem(luaCode: luaCode)

        XCTAssertEqual(problem.id, "test-001")
        XCTAssertEqual(problem.title, "Test Problem")
        XCTAssertEqual(problem.questionMarkdown, "What is 2 + 2?")
        XCTAssertEqual(problem.inputType, .numeric)
        XCTAssertEqual(controller.currentState, .presenting)
    }

    func testLoadProblemWithContext() throws {
        let luaCode = """
        local x = Problem.value
        coroutine.yield({
            id = "ctx-001",
            title = "Context Test",
            question = "Value is " .. tostring(math.floor(x))
        })
        """

        let problem = try controller.loadProblem(luaCode: luaCode, context: ["value": .number(42)])

        XCTAssertEqual(problem.questionMarkdown, "Value is 42")
    }

    func testStateTransitionsOnLoad() throws {
        let luaCode = """
        coroutine.yield({id = "trans-001", title = "Test", question = "Q"})
        """

        _ = try controller.loadProblem(luaCode: luaCode)

        // Check state transitions were recorded
        XCTAssertTrue(delegate.stateChanges.contains { $0.from == .loading && $0.to == .presenting })
    }

    func testSkipProblem() throws {
        let luaCode = """
        coroutine.yield({id = "skip-001", title = "Test", question = "Q"})
        """

        _ = try controller.loadProblem(luaCode: luaCode)
        try controller.skipProblem()

        XCTAssertEqual(delegate.completedResults.count, 1)
        XCTAssertTrue(delegate.completedResults[0].skipped)
        XCTAssertFalse(delegate.completedResults[0].completed)
    }

    func testSkipWithoutProblemThrows() {
        XCTAssertThrowsError(try controller.skipProblem()) { error in
            XCTAssertEqual(error as? ProblemControllerError, .noProblemLoaded)
        }
    }

    func testResetController() throws {
        let luaCode = """
        coroutine.yield({id = "reset-001", title = "Test", question = "Q"})
        """

        _ = try controller.loadProblem(luaCode: luaCode)
        XCTAssertNotNil(controller.currentProblem)

        controller.reset()

        XCTAssertNil(controller.currentProblem)
        XCTAssertEqual(controller.currentState, .loading)
    }

    func testDelegateReceivesMarkdown() throws {
        let luaCode = """
        renderMarkdown("# Hello World")
        coroutine.yield({id = "md-001", title = "Test", question = "Q"})
        """

        _ = try controller.loadProblem(luaCode: luaCode)

        // Give async callback time to execute
        let expectation = XCTestExpectation(description: "Markdown displayed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.delegate.displayedMarkdown.contains("# Hello World") {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDelegateReceivesSVG() throws {
        let luaCode = """
        displaySVG('<svg xmlns="http://www.w3.org/2000/svg"></svg>')
        coroutine.yield({id = "svg-001", title = "Test", question = "Q"})
        """

        _ = try controller.loadProblem(luaCode: luaCode)

        // Give async callback time to execute
        let expectation = XCTestExpectation(description: "SVG displayed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.delegate.displayedSVGs.count > 0 {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDisplaySVGRejectsInvalidSVG() throws {
        let result = try engine.evaluate("""
        return displaySVG("not svg content")
        """)

        XCTAssertEqual(result.boolValue, false)
    }

    func testSubmitAnswerWithoutProblemThrows() {
        XCTAssertThrowsError(try controller.submitAnswer(.number(42))) { error in
            XCTAssertEqual(error as? ProblemControllerError, .noProblemLoaded)
        }
    }

    func testRequestHintWithoutProblemThrows() {
        XCTAssertThrowsError(try controller.requestHint(type: .symbolic)) { error in
            XCTAssertEqual(error as? ProblemControllerError, .noProblemLoaded)
        }
    }
}
