import SwiftUI

extension Detail {
    struct Navigation: View {
        let web: Web
        @State private var back = false
        @State private var forward = false
        @State private var loading = false
        
        var body: some View {
            HStack(spacing: 0) {
                Bar.Item(size: 20, icon: "chevron.backward") {
                    web.goBack()
                }
                .foregroundStyle(back ? .primary : .tertiary)
                .allowsHitTesting(back)
                
                Spacer()
                
                Bar.Item(size: 20, icon: loading ? "xmark" : "arrow.clockwise") {
                    if loading {
                        web.stopLoading()
                    } else {
                        web.reload()
                    }
                }
                
                Spacer()
                
                Bar.Item(size: 20, icon: "chevron.forward") {
                    web.goForward()
                }
                .foregroundStyle(forward ? .primary : .tertiary)
                .allowsHitTesting(forward)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            .onReceive(web.publisher(for: \.canGoBack)) {
                back = $0
            }
            .onReceive(web.publisher(for: \.canGoForward)) {
                forward = $0
            }
            .onReceive(web.publisher(for: \.isLoading)) {
                loading = $0
            }
        }
    }
}
