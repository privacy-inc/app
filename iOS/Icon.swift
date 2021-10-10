import SwiftUI
import Specs

struct Icon: View {
    var size = CGFloat(32)
    let access: AccessType
    let publisher: Favicon.Pub
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            } else {
                Image(systemName: "app")
                    .font(.title.weight(.light))
                    .foregroundStyle(.quaternary)
            }
        }
        .allowsHitTesting(false)
        .frame(width: size, height: size)
        .onReceive(publisher) {
            image = $0
        }
    }
}
