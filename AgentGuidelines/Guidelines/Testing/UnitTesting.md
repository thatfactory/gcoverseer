# Unit and Integration Testing

## Framework choice

- Use Swift Testing (`import Testing`) for new unit and integration tests.
- Keep XCTest for UI automation based on XCUIAutomation and for `measure`-based performance tests.
- Do not migrate unrelated tests while implementing a focused feature or fix.
- After removing XCTest, add direct imports such as Foundation when the test relied on XCTest's transitive exports.

## Structure

- Organize test intent with `// Given`, `// When`, and `// Then` where the phases are meaningful.
- Prefer `struct` suites. Use a reference type only when lifecycle or identity requires it.
- Use suite initialization and `deinit` only for genuine shared setup and cleanup.
- Keep each test focused on one behavior and name it in domain language.
- Mirror production physical folders under the test target.
- Put reusable mocks and fixtures under the test target's `Mocks/` folder.
- Use shared test tags for recurring classification and keep their declarations alphabetical. Prefer small composable tags that can be combined to describe a test without repeating ad hoc metadata.
- Add a short `///` comment describing each mock's test purpose.

## Assertions and control flow

- Use `@Test` for tests and traits.
- Use `#expect` for assertions that allow the test to continue.
- Use `#require` for prerequisites whose failure must stop the current test.
- Prefer exact thrown-error expectations when the particular error is part of the contract.
- Use confirmation APIs for callback or delegate behavior rather than hand-built counters and arbitrary delays.
- Record known failures with Swift Testing's known-issue support instead of silently disabling coverage.

## Concurrency

- Assume Swift Testing may run tests concurrently and on arbitrary tasks.
- Make tests independent by default.
- Use `.serialized` only when a suite has a real shared-state dependency that cannot reasonably be removed.
- Add `@MainActor` only when the system under test requires main-actor isolation.
- Prefer async test functions and structured concurrency over expectations combined with arbitrary sleeps.
- Inject clocks, services, identifier generators, and providers to make asynchronous behavior deterministic.

## Repetition

- Prefer parameterized tests when the same behavior is exercised with multiple inputs and expected outputs.
- Keep argument cases readable and give complex cases a small named model.
- Do not loop manually inside one test when individual parameterized cases would produce better failure reporting.

## Execution

- Prefer Xcode MCP for discovering and running the relevant test plan or test target.
- Use XcodeBuildMCP only when Xcode MCP is unavailable or fails to complete the workflow.
- Start with the smallest relevant test selection, then run the broader affected suite when risk justifies it.
- Report which tests ran and whether any relevant tests could not be executed.

Follow [Xcode MCP](../Xcode/MCP.md) for build and runtime verification.
