import AppKit
import Domains
import Specs

struct ListInfo: Identifiable, Hashable {
    var id: String {
        website.id
    }
    
    let first: Bool
    let text: NSAttributedString
    let website: Website
    
    init(website: Website, first: Bool) {
        text = .make(lineBreak: .byTruncatingTail) {
            if !website.title.isEmpty {
                $0.append(.make(website.title, attributes: [
                    .font: NSFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: NSColor.labelColor]))
                $0.newLine()
            }
            
            $0.append(.make(website.id.domainMinimal, attributes: [
                .font: NSFont.preferredFont(forTextStyle: .callout),
                .foregroundColor: NSColor.tertiaryLabelColor]))
        }
        self.website = website
        self.first = first
    }
    
    func hash(into: inout Hasher) {
        into.combine(id)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}