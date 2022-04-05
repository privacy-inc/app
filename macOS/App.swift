import AppKit
import StoreKit
import UserNotifications
import Specs

@NSApplicationMain final class App: NSApplication, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    required init?(coder: NSCoder) { nil }
    override init() {
        super.init()
        delegate = self
        
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handle(_:_:)),
            forEventClass: .init(kInternetEventClass),
            andEventID: .init(kAEGetURL)
        )
    }
    
    func applicationWillFinishLaunching(_: Notification) {
        mainMenu = Menu()
    }
    
    func applicationDidFinishLaunching(_: Notification) {
        registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = self

        cloud.ready.notify(queue: .main) {
            cloud.pull.send()
            
            self.newWindow()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                switch Defaults.action {
                case .rate:
                    SKStoreReviewController.requestReview()
                case .froob:
                    (NSApp.anyWindow() ?? Froob())
                        .makeKeyAndOrderFront(nil)
                case .none:
                    break
                }
                
                Task {
                    _ = await UNUserNotificationCenter.request()
                }
            }
        }
    }
    
    func applicationDidBecomeActive(_: Notification) {
        cloud.pull.send()
    }
    
    func application(_: NSApplication, didReceiveRemoteNotification: [String : Any]) {
        cloud.pull.send()
    }
    
    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if hasVisibleWindows {
            windows
                .filter(\.isMiniaturized)
                .forEach {
                    $0.deminiaturize(nil)
                }
        } else {
            newWindow()
        }
        return false
    }
    
    func application(_ app: NSApplication, open: [URL]) {
        cloud.ready.notify(queue: .main) {
            open
                .forEach(app.open(url:))
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        await center.present(notification)
    }
    
    func application(_: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken: Data) {
        
    }
    
    func application(_: NSApplication, didFailToRegisterForRemoteNotificationsWithError: Error) {
        
    }
    
    @objc override func orderFrontStandardAboutPanel(_ sender: Any?) {
        (anyWindow() ?? About())
            .makeKeyAndOrderFront(nil)
    }
    
    @objc func showPreferencesWindow(_ sender: Any?) {
        (anyWindow() ?? Preferences())
            .makeKeyAndOrderFront(nil)
    }
    
    @objc private func handle(_ event: NSAppleEventDescriptor, _: NSAppleEventDescriptor) {
        cloud
            .ready
            .notify(queue: .main) {
                event
                    .paramDescriptor(forKeyword: keyDirectObject)
                    .flatMap(\.stringValue?.removingPercentEncoding)
                    .flatMap(URL.init(string:))
                    .map(NSApp.open(url:))
            }
    }
}
