import WebKit
import Combine
import Specs

class Webview: WKWebView, WKNavigationDelegate, WKUIDelegate {
    final var subs = Set<AnyCancellable>()
    final let progress = PassthroughSubject<Double, Never>()
    private let settings: Specs.Settings.Configuration
    
//    override var isEditable: Bool {
//        false
//    }
    
    required init?(coder: NSCoder) { nil }
    @MainActor init(configuration: WKWebViewConfiguration,
                    settings: Specs.Settings.Configuration,
                    dark: Bool) {
        
        self.settings = settings

        configuration.suppressesIncrementalRendering = false
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = settings.popups && settings.javascript
        configuration.preferences.isFraudulentWebsiteWarningEnabled = !settings.http
        configuration.defaultWebpagePreferences.allowsContentJavaScript = settings.popups && settings.javascript
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.addUserScript(.init(source: Script.favicon.script, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.addUserScript(.init(source: settings.scripts, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        
        if dark && settings.dark {
            configuration.userContentController.addUserScript(.init(source: Script.dark.script, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }
        
        switch settings.autoplay {
        case .none:
            configuration.mediaTypesRequiringUserActionForPlayback = .all
        case .audio:
            configuration.mediaTypesRequiringUserActionForPlayback = .video
        case .video:
            configuration.mediaTypesRequiringUserActionForPlayback = .audio
        case .all:
            configuration.mediaTypesRequiringUserActionForPlayback = []
        }
        
    #if DEBUG
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
    #endif

        super.init(frame: .zero, configuration: configuration)
        navigationDelegate = self
        uiDelegate = self
        allowsBackForwardNavigationGestures = true
//        allowsMagnification = true
        
        if settings.history {
            publisher(for: \.url)
                .compactMap {
                    $0
                }
                .removeDuplicates()
                .combineLatest(publisher(for: \.title)
                    .compactMap {
                        $0
                    }
                    .removeDuplicates())
                .debounce(for: .seconds(1), scheduler: DispatchQueue.global(qos: .utility))
                .sink { url, title in
                    Task
                        .detached(priority: .utility) {
                            await cloud.history(url: url, title: title)
                        }
                }
                .store(in: &subs)
        }
        
        publisher(for: \.estimatedProgress)
            .subscribe(progress)
            .store(in: &subs)
        
        Task {
            guard
                let rules = try? await WKContentRuleListStore.default().compileContentRuleList(
                    forIdentifier: "rules",
                    encodedContentRuleList: settings.blockers(dark: dark))
            else { return }
            configuration.userContentController.add(rules)
        }
    }
    
    deinit {
        stopLoading()
        uiDelegate = nil
        navigationDelegate = nil
        
        configuration.userContentController.removeScriptMessageHandler(forName: Script.location.method)
    }
    
    func deeplink(url: URL) {
        
    }
    
    func privacy(url: URL) {
        
    }
    
    func message(url: URL?, title: String, icon: String) {

    }
    
    func webView(_ webView: WKWebView, didFinish: WKNavigation!) {
        if settings.favicons {
            Task {
                guard
                    let website = webView.url,
                    await favicon.request(for: website),
                    let url = try? await (webView.evaluateJavaScript(Script.favicon.method)) as? String,
                    settings.http || (!settings.http && url.hasPrefix("https://"))
                else { return }

                await favicon.received(url: url, for: website)
            }
        }
        
        if !settings.timers {
            evaluateJavaScript(Script.unpromise.script)
        }
    }
    
    final func load(url: URL) {
        load(.init(url: url))
    }
        
    func error(url: URL?, description: String) {
        progress.send(1)
        message(url: url, title: description, icon: "exclamationmark.triangle.fill")

        Task
            .detached(priority: .utility) {
                guard let url = url else { return }
                await cloud.history(url: url, title: description)
            }
    }
    
    final func webView(_: WKWebView, respondTo: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        settings.http
        ? (.useCredential, respondTo.protectionSpace.serverTrust.map(URLCredential.init(trust:)))
        : (.performDefaultHandling, nil)
    }
    
    final func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) {
        guard
            (withError as NSError).code != NSURLErrorCancelled,
            (withError as NSError).code != Invalid.frameLoadInterrupted.rawValue
        else { return }
        
        error(url: (withError as? URLError)
                .flatMap(\.failingURL)
                ?? url
                ?? {
                    $0?["NSErrorFailingURLKey"] as? URL
                } (withError._userInfo as? [String : Any]), description: withError.localizedDescription)
    }
    
    final func webView(_: WKWebView, decidePolicyFor: WKNavigationAction, preferences: WKWebpagePreferences) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        switch await cloud.policy(request: decidePolicyFor.request.url!, from: url!) {
        case .allow:
            if decidePolicyFor.shouldPerformDownload {
                return (.download, preferences)
            } else {
#if DEBUG
                print("allow \(decidePolicyFor.request.url!)")
#endif
                preferences.allowsContentJavaScript = settings.javascript
                return (.allow, preferences)
            }
        case .ignore:
            decidePolicyFor
                .targetFrame
                .map(\.isMainFrame)
                .map {
                    guard $0 else { return }
                    error(url: decidePolicyFor.request.url, description: "There was an error")
                }
        case .block:
            decidePolicyFor
                .targetFrame
                .map(\.isMainFrame)
                .map {
                    guard $0 else { return }
                    error(url: decidePolicyFor.request.url, description: "Blocked")
                }
        case .deeplink:
            deeplink(url: decidePolicyFor.request.url!)
        case .privacy:
            privacy(url: decidePolicyFor.request.url!)
        }
        return (.cancel, preferences)
    }
    
    final func webView(_: WKWebView, decidePolicyFor: WKNavigationAction) async -> WKNavigationActionPolicy {
        decidePolicyFor.shouldPerformDownload ? .download : .allow
    }
    
    final func webView(_: WKWebView, decidePolicyFor: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        guard
            let response = decidePolicyFor.response as? HTTPURLResponse,
            let contentType = response.value(forHTTPHeaderField: "Content-Type"),
            contentType.range(of: "attachment", options: .caseInsensitive) != nil
        else {
            return decidePolicyFor.canShowMIMEType ? .allow : .download
        }
        return .download
    }
    
    final func webView(_: WKWebView, navigationAction: WKNavigationAction, didBecome: WKDownload) {
        didBecome.delegate = self
    }
    
    final func webView(_: WKWebView, navigationResponse: WKNavigationResponse, didBecome: WKDownload) {
        didBecome.delegate = self
    }
    
    final func download(_ download: WKDownload, didFailWithError: Error, resumeData: Data?) {
        error(url: download.originalRequest?.url,
              description: (didFailWithError as NSError).localizedDescription)
    }
    
    @MainActor final class func clear() async {
        URLCache.shared.removeAllCachedResponses()
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        await clear(store: .default())
        await clear(store: .nonPersistent())
    }
    
    @MainActor private class func clear(store: WKWebsiteDataStore) async {
        for record in await store.dataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) {
            await store.removeData(ofTypes: record.dataTypes, for: [record])
        }
        await store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast)
    }
}
