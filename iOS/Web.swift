import SwiftUI
import WebKit
import Combine
import Specs

final class Web: Webview, UIViewRepresentable {
    let tab = PassthroughSubject<URL, Never>()
    
    required init?(coder: NSCoder) { nil }
    init(history: UInt16, settings: Specs.Settings.Configuration) {
        print("web init")
    
        let configuration = WKWebViewConfiguration()
        configuration.dataDetectorTypes = [.link]
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        configuration.allowsInlineMediaPlayback = true
        configuration.ignoresViewportScaleLimits = true
        
        let dark = UIApplication.shared.dark
        
        super.init(configuration: configuration, history: history, settings: settings, dark: dark)
        scrollView.keyboardDismissMode = .none
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.clipsToBounds = false
        scrollView.indicatorStyle = dark && settings.dark ? .white : .default
    }
    
    deinit {
        scrollView.delegate = nil
        print("web gone")
    }
    
    override func external(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    override func error(url: URL?, description: String) {
        
    }
    
    func webView(_: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
        UIApplication.shared.hide()
    }

    func webView(_: WKWebView, createWebViewWith: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if (action.targetFrame == nil && action.navigationType == .other) || action.navigationType == .linkActivated {
            _ = action
                .request
                .url
                .map(load)
        }
        return nil
    }
    
    func webView(_: WKWebView, contextMenuConfigurationFor: WKContextMenuElementInfo) async -> UIContextMenuConfiguration? {
        .init(identifier: nil, previewProvider: nil, actionProvider: { elements in
            var elements = elements
                .filter {
                    guard let name = ($0 as? UIAction)?.identifier.rawValue else { return true }
                    return !(name.hasSuffix("Open") || name.hasSuffix("List"))
                }
            
            if let url = contextMenuConfigurationFor
                .linkURL {
                    elements
                        .insert(UIAction(title: NSLocalizedString("Open in new tab", comment: ""),
                                         image: UIImage(systemName: "plus.square.on.square"))
                        { [weak self] _ in
                            self?.tab.send(url)
                        }, at: 0)
                }
            return .init(title: "", children: elements)
        })
    }
    
    func webView(_: WKWebView, contextMenuForElement element: WKContextMenuElementInfo, willCommitWithAnimator: UIContextMenuInteractionCommitAnimating) {
        if let url = element.linkURL {
            load(url)
        } else if let data = (willCommitWithAnimator.previewViewController?.view.subviews.first as? UIImageView)?.image?.pngData() {
            load(data.temporal("image.png"))
        }
    }
    
//    private func found(_ offset: CGFloat) {
//        scrollView.scrollRectToVisible(.init(x: 0,
//                                             y: offset + scrollView.contentOffset.y - (offset > 0 ? 160 : -180),
//                                             width: 320,
//                                             height: 320),
//                                       animated: true)
//    }
    
    func makeUIView(context: Context) -> Web {
        self
    }

    func updateUIView(_: Web, context: Context) {

    }
}
