import Testing
@testable import App

@Test func counterIncrementsAndResets() {
    var counter = Counter()

    counter.increment()
    counter.increment()
    #expect(counter.value == 2)

    counter.reset()
    #expect(counter.value == 0)
}
