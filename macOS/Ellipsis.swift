import AppKit
import Combine
import UserNotifications

final class Ellipsis: NSPopover {
    private var subs = Set<AnyCancellable>()
    private weak var web: Web?
    
    required init?(coder: NSCoder) { nil }
    init(web: Web, origin: NSView) {
        self.web = web
        
        super.init()
        behavior = .semitransient
        contentSize = .zero
        contentViewController = .init()
        
        let view = NSView()
        contentViewController!.view = view
        
        let disable = Switch(title: "Disable text selection", target: self, action: #selector(disable))
        disable.control.state = web.configuration.preferences.isTextInteractionEnabled ? .off : .on
        
        let share = Option(title: "Share", symbol: "square.and.arrow.up")
        share
            .click
            .sink { [weak self] in
                self?.close()
                
                let pop = Share(web: web, origin: origin)
                pop.show(relativeTo: origin.bounds, of: origin, preferredEdge: .maxY)
                pop.contentViewController!.view.window!.makeKey()
            }
            .store(in: &subs)
        
        let bookmark = Option(title: "Bookmark", symbol: "bookmark")
        bookmark
            .click
            .sink { [weak self] in
                self?.close()
                
                Task
                    .detached {
                        await UNUserNotificationCenter.send(message: "Bookmark added!")
                        await cloud.bookmark(history: web.history)
                    }
            }
            .store(in: &subs)
        
        let pause = Option(title: "Pause all media", symbol: "pause.circle.fill")
        pause
            .click
            .sink { [weak self] in
                self?.close()
                
                Task {
                    await MainActor
                        .run {
                            Task {
                                await web.pauseAllMediaPlayback()
                            }
                        }
                }
            }
            .store(in: &subs)
        
        let stack = NSStackView(views: [
            header(web: web),
            Separator(mode: .horizontal),
            disable,
            Separator(mode: .horizontal),
            share,
            Separator(mode: .horizontal),
            bookmark,
            Separator(mode: .horizontal),
            pause
        ])
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        view.addSubview(stack)

        stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 30).isActive = true
        stack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30).isActive = true
        stack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -30).isActive = true
        stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        stack.widthAnchor.constraint(equalToConstant: 280).isActive = true
    }
    
    private func header(web: Web) -> NSView {
        let view = NSView()
        
        let icon = Icon(size: 48)
        view.addSubview(icon)
        
        let text = Text(vibrancy: true)
        text.maximumNumberOfLines = 2
        text.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.addSubview(text)
        
        icon.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        icon.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        icon.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        
        text.centerYAnchor.constraint(equalTo: icon.centerYAnchor).isActive = true
        text.leftAnchor.constraint(equalTo: icon.rightAnchor, constant: 10).isActive = true
        text.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor).isActive = true
        
        web
            .publisher(for: \.url)
            .compactMap {
                $0
            }
            .removeDuplicates()
            .combineLatest(web
                            .publisher(for: \.title)
                            .compactMap {
                                $0
                            }
                            .removeDuplicates())
            .sink { url, title in
                let copy: AttributedString
                
                if title.isEmpty {
                    copy = .init(url.absoluteString, attributes: .init([
                        .font: NSFont.preferredFont(forTextStyle: .body),
                        .foregroundColor: NSColor.secondaryLabelColor]))
                } else {
                    copy = .init(title, attributes: .init([
                        .font: NSFont.preferredFont(forTextStyle: .title3),
                        .foregroundColor: NSColor.labelColor]))
                    + .newLine
                    + .init(url.absoluteString, attributes: .init([
                        .font: NSFont.preferredFont(forTextStyle: .body),
                        .foregroundColor: NSColor.secondaryLabelColor]))
                }
                
                text.attributedStringValue = .init(copy
                                                    .with(truncating: .byTruncatingTail))
            }
            .store(in: &subs)
        
        Task {
            guard let image = await cloud.website(history: web.history)?.access.icon else { return }
            icon.icon(icon: image)
        }
        
        return view
    }
    
    @objc private func disable(_ toggle: NSSwitch) {
        web?.configuration.preferences.isTextInteractionEnabled = toggle.state == .off
    }
}