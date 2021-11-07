import AppKit
import Combine
import UserNotifications

extension Preferences.General {
    final class Browser: NSView {
        private var subs = Set<AnyCancellable>()
        
        required init?(coder: NSCoder) { nil }
        init() {
            super.init(frame: .zero)
            
            let title = Text(vibrancy: true)
            title.textColor = .labelColor
            title.font = .preferredFont(forTextStyle: .headline)
            title.stringValue = "Default Browser"
            
            var copy = (try? AttributedString(markdown: Copy.browser, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? .init(Copy.browser)
            copy.setAttributes(.init([
                .font: NSFont.preferredFont(forTextStyle: .body),
                .foregroundColor: NSColor.secondaryLabelColor]))
            
            let text = Text(vibrancy: true)
            text.textColor = .secondaryLabelColor
            text.font = .preferredFont(forTextStyle: .callout)
            text.attributedStringValue = .init(copy)
            
            let option = Preferences.Option(title: "Make default Browser", symbol: "magnifyingglass")
            option
                .click
                .sink { [weak self] in
                    LSSetDefaultHandlerForURLScheme(URL.Scheme.http.rawValue as CFString, "incognit" as CFString)
                    LSSetDefaultHandlerForURLScheme(URL.Scheme.https.rawValue as CFString, "incognit" as CFString)
                    self?.window?.close()
                    
                    Task {
                        await UNUserNotificationCenter.send(message: "Made default Browser")
                    }
                }
                .store(in: &subs)
            
            let badge = Image(icon: "checkmark.circle.fill", vibrancy: false)
            badge.symbolConfiguration = .init(textStyle: .title1)
                .applying(.init(hierarchicalColor: .systemBlue))
            badge.isHidden = true
            
            let stack = NSStackView(views: [title, text, badge, option])
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.orientation = .vertical
            stack.spacing = 20
            addSubview(stack)
            
            if isDefault {
                badge.isHidden = false
                text.isHidden = true
                option.isHidden = true
            }
            
            stack.topAnchor.constraint(equalTo: topAnchor).isActive = true
            stack.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            stack.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
            stack.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            
            text.widthAnchor.constraint(lessThanOrEqualToConstant: 240).isActive = true
        }
        
        private var isDefault: Bool {
            NSWorkspace
                .shared
                .urlForApplication(toOpen: URL(string: URL.Scheme.http.rawValue + "://")!)
                .map {
                    $0.lastPathComponent == Bundle.main.bundleURL.lastPathComponent
                }
                ?? false
        }
    }
}