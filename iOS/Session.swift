import Foundation
import SwiftUI
import Specs

final class Session: ObservableObject {
    @Published var current: Int? = 0
    @Published var froob = false
    var items: [Item]
    var dark = false
    
    init() {
        let item = Item(flow: .search(false))
        items = [item]
    }
    
    func index(_ of: Web) -> Int {
        items
            .firstIndex {
                $0.web === of
            }!
    }
    
    @MainActor func search(string: String, index: Int) async {
        guard let url = try? await cloud.search(string)
        else {
            if items[index].web != nil {
                withAnimation(.easeInOut(duration: 0.4)) {
                    items[index].flow = .web
                    objectWillChange.send()
                }
            }
            return
        }
        await open(url: url, index: index)
    }
    
    @MainActor func open(url: URL, index: Int) async {
        if items[index].web == nil {
            items[index].web = await .init(session: self, settings: cloud.model.settings.configuration, dark: dark)
        }
        
        items[index].flow = .web
        objectWillChange.send()
        items[index].web!.load(url: url)
    }
}
