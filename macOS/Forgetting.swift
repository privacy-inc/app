import AppKit
import Combine

final class Forgetting: NSPopover {
    private var subs = Set<AnyCancellable>()
    
    required init?(coder: NSCoder) { nil }
    init(behaviour: NSPopover.Behavior) {
        super.init()
        behavior = behaviour
        contentSize = .init(width: 200, height: 200)
        contentViewController = .init()
        
        let view = NSView(frame: .init(origin: .zero, size: contentSize))
        contentViewController!.view = view
        
        let title = Text(vibrancy: true)
        title.stringValue = "Forget"
        title.font = .preferredFont(forTextStyle: .title3)
        title.textColor = .secondaryLabelColor
        
        let cache = Option(title: "Cache", image: "trash")
        cache
            .click
            .sink { [weak self] in
                Forget.cache()
                self?.close()
            }
            .store(in: &subs)
        
        let history = Option(title: "History", image: "clock")
        history
            .click
            .sink { [weak self] in
                Forget.history()
                NSApp.closeAllWindows()
                self?.close()
            }
            .store(in: &subs)
        
        let activity = Option(title: "Activity", image: "chart.xyaxis.line")
        activity
            .click
            .sink { [weak self] in
                Forget.activity()
                self?.close()
            }
            .store(in: &subs)
        
        let everything = Option(title: "Everything", image: "flame")
        everything
            .click
            .sink { [weak self] in
                Forget.everything()
                NSApp.closeAllWindows()
                self?.close()
            }
            .store(in: &subs)
        
        let stack = NSStackView(views: [title, Separator(mode: .horizontal), cache, history, activity, everything])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        view.addSubview(stack)
        
        stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 30).isActive = true
        stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        stack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
        stack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
    }
}
