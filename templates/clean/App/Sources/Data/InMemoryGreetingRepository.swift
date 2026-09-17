struct InMemoryGreetingRepository: GreetingProviding {
    func greeting(for name: String) -> Greeting {
        Greeting(message: "Hello, \(name)!")
    }
}
