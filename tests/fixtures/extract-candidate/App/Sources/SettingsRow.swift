import SwiftUI

struct SettingsRow: View {
    let title: String
    let isOn: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
        }
        .padding()
    }
}
