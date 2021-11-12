import AppKit
import Combine

final class History: Websites {
    deinit {
        print("history gone")
    }
    
    override init() {
        super.init()
        setFrameAutosaveName("History")
        navigation.stringValue = "History"
        
        cloud
            .first()
            .merge(with: cloud
                    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main))
            .map(\.history)
            .map {
                $0
                    .enumerated()
                    .map {
                        .init(id: $0.0, history: $0.1)
                    }
            }
            .removeDuplicates()
            .sink { [weak self] in
                self?.list.info.send($0)
            }
            .store(in: &subs)
        
        list
            .open
            .sink { index in
                Task {
                    await NSApp.open(id: cloud.model.history[index].id)
                }
            }
            .store(in: &subs)
        
        list
            .delete
            .sink { index in
                Task
                    .detached(priority: .utility) {
                        await cloud.delete(history: cloud.model.history[index].id)
                    }
            }
            .store(in: &subs)
    }
    
    @MainActor private func open(index: Int) {
        
    }
}