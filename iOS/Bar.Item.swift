import SwiftUI

extension Bar {
    struct Item: View {
        let size: CGFloat
        let icon: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Image(systemName: icon)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: size, weight: .light))
                    .frame(width: 70, height: 34)
                    .contentShape(Rectangle())
            }
        }
    }
}
