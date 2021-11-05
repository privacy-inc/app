import UIKit
import WebKit

extension Webview: WKDownloadDelegate {
    final var defaultBackground: UIColor {
        .secondarySystemBackground
        .resolvedColor(with:
                            .init(userInterfaceStyle: dark ? .dark : .light))
    }
    
    final func download(_ download: WKDownload, decideDestinationUsing: URLResponse, suggestedFilename: String) async -> URL? {
        decideDestinationUsing
            .url
            .map {
                try? UIApplication.shared.share(Data(contentsOf: $0).temporal(suggestedFilename))
            }
        
        await download.cancel()
        return nil
    }
}
