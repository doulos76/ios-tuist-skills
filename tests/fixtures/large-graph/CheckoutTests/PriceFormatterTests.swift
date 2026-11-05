import Testing
@testable import CheckoutFeature

@Test func formatsDollarsAndCents() {
    #expect(PriceFormatter.format(cents: 1205) == "$12.05")
    #expect(PriceFormatter.format(cents: 7) == "$0.07")
}

@Test func cartTotalIsFormatted() {
    var cart = Cart()
    cart.add("Lamp", cents: 1999)
    cart.add("Bulb", cents: 1)
    #expect(cart.formattedTotal == "$20.00")
}
