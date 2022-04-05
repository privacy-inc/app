import WebKit
import Combine
import UniformTypeIdentifiers
import UserNotifications
import Specs

final class Web: Webview {
    let item: UUID
    private weak var status: Status!
    private var destination = Destination.here
    
    required init?(coder: NSCoder) { nil }
    init(status: Status,
         item: UUID,
         settings: Specs.Settings.Configuration) {
        
        self.status = status
        self.item = item
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        configuration.preferences.setValue(true, forKey: "fullScreenEnabled")
        configuration.setValue(false, forKey: "drawsBackground")
        
        configuration.userContentController.addUserScript(.init(source: Script.location.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        
        super.init(configuration: configuration, settings: settings, dark: NSApp.effectiveAppearance.name != .aqua)
        translatesAutoresizingMaskIntoConstraints = false
        customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.4 Safari/605.1.15"

        layer = Layer()
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        configuration.userContentController.addScriptMessageHandler(Location(), contentWorld: .page, name: Script.location.method)
    }
    
    override func external(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
    
    override func error(error: Specs.Fail) {
        status.change(flow: .error(self, error), id: item)
    }
    
    func webView(_: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
        window?.makeFirstResponder(self)
    }
    
    func webView(_: WKWebView, createWebViewWith: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        switch action.navigationType {
        case .linkActivated:
            if action.sourceFrame.isMainFrame {
                _ = action
                    .request
                    .url
                    .map(load)
            }
        case .other:
            if action.targetFrame == nil && action.sourceFrame.isMainFrame {
                action
                    .request
                    .url
                    .map { url in
                        switch destination {
                        case .here:
                            load(url: url)
                        case let .tab(change):
                            if change {
                                NSApp.open(url: url)
                            } else {
                                NSApp.silent(url: url)
                            }
                        case .window:
                            NSApp.window(url: url)
                        case .download:
                            Task
                                .detached(priority: .utility) { [weak self] in
                                    await self?.download(url: url)
                                }
                        }
                        destination = .here
                    }
            }
        default:
            break
        }
        return nil
    }
    
    override func willOpenMenu(_ menu: NSMenu, with: NSEvent) {
        menu.remove(id: "WKMenuItemIdentifierSearchWeb")

        if let image = menu.remove(id: "WKMenuItemIdentifierOpenImageInNewWindow") {
            let here = image.immitate(with: "Open Image", action: #selector(here(item:)))
            here.target = self
            
            let tabStay = image.immitate(with: "Open Image in New Tab", action: #selector(tab(stay:)))
            tabStay.target = self
            
            let tabChange = image.immitate(with: "Open Image in New Tab and Change", action: #selector(tab(change:)))
            tabChange.target = self
            
            menu.items = [
                here,
                tabStay,
                tabChange,
                image,
                .separator()
            ]
            + menu.items
            
            menu
                .mutate(id: "WKMenuItemIdentifierDownloadImage") {
                    $0.target = self
                    $0.action = #selector(download(item:))
                    $0.representedObject = image
                }
        }
        
        if let window = menu.remove(id: "WKMenuItemIdentifierOpenLinkInNewWindow") {
            window.title = "Open in New Window"
            
            let tabStay = window.immitate(with: "Open in New Tab", action: #selector(tab(stay:)))
            tabStay.target = self
            
            let tabChange = window.immitate(with: "Open in New Tab and Change", action: #selector(tab(change:)))
            tabChange.target = self
            
            menu.items = [
                tabStay,
                tabChange,
                window,
                .separator()
            ]
            + menu.items
            
            menu
                .mutate(id: "WKMenuItemIdentifierDownloadLinkedFile") {
                    $0.target = self
                    $0.action = #selector(download(item:))
                    $0.representedObject = window
                }
        }
    }
    
    func tryAgain() {
        if case let .error(_, error) = status.flow(of: item) {
            load(url: error.url)
            status.change(flow: .web(self), id: item)
        }
    }
    
    func dismiss() {
//        Task
//            .detached(priority: .utility) { [weak self] in
//                await self?.status.dismiss()
//            }
    }
    
    @objc func share(_ item: NSMenuItem) {
        guard
            let url = url,
            let service = item.representedObject as? NSSharingService
        else { return }
        service.perform(withItems: [url])
    }
    
    @objc func saveAs() {
        saveAs(types: [])
    }
    
    @objc func exportAsWebarchive() {
        guard url?.pathExtension != "webarchive" else {
            saveAs(types: [.webArchive])
            return
        }
        createWebArchiveData { [weak self] in
            guard
                case let .success(data) = $0,
                let name = self?.url?.file("webarchive")
            else { return }
            NSSavePanel.save(data: data, name: name, types: [.webArchive])
        }
    }
    
   @objc func printPage() {
       let info = NSPrintInfo.shared
       info.horizontalPagination = .automatic
       info.verticalPagination = .automatic
       info.isVerticallyCentered = false
       info.isHorizontallyCentered = false
       info.leftMargin = 10
       info.rightMargin = 10
       info.topMargin = 10
       info.bottomMargin = 10
       
       let operation = printOperation(with: info)
       operation.view?.frame = bounds
       operation.runModal(for: window!, delegate: nil, didRun: nil, contextInfo: nil)
    }
    
    @objc func actualSize() {
        pageZoom = 1
    }
    
    @objc func zoomIn() {
        pageZoom *= 1.1
    }
    
    @objc func zoomOut() {
        pageZoom /= 1.1
    }
    
    @objc func copyLink() {
        guard let url = url else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
        
        Task
            .detached(priority: .utility) {
                await UNUserNotificationCenter.send(message: "Link URL copied")
            }
    }
    
    @MainActor @objc func exportAsPdf() {
        guard url?.pathExtension.lowercased() != "pdf" else {
            saveAs(types: [.pdf])
            return
        }
        Task {
            guard
                let name = url?.file("pdf"),
                let pdf = try? await pdf()
            else { return }
            NSSavePanel.save(data: pdf, name: name, types: [.pdf])
        }
    }
    
    @MainActor @objc func exportAsSnapshot() {
        switch url?.pathExtension.lowercased() {
        case "png":
            saveAs(types: [.png])
        case "jpg", "jpeg":
            saveAs(types: [.jpeg])
        case "bmp":
            saveAs(types: [.bmp])
        case "gif":
            saveAs(types: [.gif])
        default:
            Task {
                guard
                    let name = url?.file("png"),
                    let image = try? await takeSnapshot(configuration: nil),
                    let tiff = image.tiffRepresentation,
                    let data = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
                else { return }
                NSSavePanel.save(data: data, name: name, types: [.png])
            }
        }
    }
    
    private func saveAs(types: [UTType]) {
        url?
            .download
            .map { download in
                (try? Data(contentsOf: download))
                    .map {
                        NSSavePanel.save(data: $0, name: download.lastPathComponent, types: types)
                    }
            }
    }
    
    private func download(url: URL) async {
        guard let (data, _) = try? await URLSession.shared.data(from: url, delegate: nil) else { return }
        await MainActor
            .run {
                NSSavePanel.save(data: data, name: url.lastPathComponent, types: [])
            }
    }
    
    @objc private func here(item: NSMenuItem) {
        destination = .here
        item.activate()
    }
    
    @objc private func tab(change item: NSMenuItem) {
        destination = .tab(true)
        item.activate()
    }

    @objc private func tab(stay item: NSMenuItem) {
        destination = .tab(false)
        item.activate()
    }

    @objc private func download(item: NSMenuItem) {
        destination = .download
        item.activate()
    }
}
