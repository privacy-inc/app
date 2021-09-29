import SwiftUI
import Specs

struct Landing: View {
    let tabs: () -> Void
    let search: () -> Void
    let history: (Int) -> Void
    @State private var cards = [Cards.report,
                                .activity,
                                .bookmarks,
                                .history]
    
    var body: some View {
        ScrollView {
            ForEach(cards) {
                switch $0 {
                case .report:
                    Report()
                case .activity:
                    Activity()
                case .bookmarks:
                    Bookmarks()
                case .history:
                    History(select: history)
                }
            }
        }
        .clipped()
        .background(.ultraThickMaterial)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Bar(search: search) {
                Button {
                    
                } label: {
                    Image(systemName: "gear")
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 64)
                }
                Spacer()
            } trailing: {
                Spacer()
                Button(action: tabs) {
                    Image(systemName: "square.on.square.dashed")
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 64)
                }
            }
        }
    }
}

enum Cards: Identifiable {
    var id: Self {
        self
    }
    
    case
    report,
    activity,
    bookmarks,
    history
}
