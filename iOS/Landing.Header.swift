import SwiftUI

extension Landing {
    struct Header<Content>: View where Content : View {
        let title: String
        let content: Content
        
        @inlinable init(_ title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        
        var body: some View {
            VStack {
                Text(title)
                    .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                    .font(.headline)
                    .padding(.leading)
                content
            }
            .padding(.vertical)
        }
    }
}
