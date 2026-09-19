import Testing

@testable import GCOverseer

@Suite struct DefaultValues {
    @Test("No controllers are connected by default")
    func initialState() async {
        let overseer = GCOverseer()
        #expect(overseer.controllers.isEmpty)
    }

    @Test("isLogging is enabled by default")
    func isLoggingEnabled() {
        let overseer = GCOverseer()
        #expect(overseer.isLoggingEnabled)
    }
}
