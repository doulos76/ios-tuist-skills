struct Greeting: Equatable {
    let message: String
}

protocol GreetingProviding {
    func greeting(for name: String) -> Greeting
}
