import AppKit

extension Search {
    final class Cell: NSTextFieldCell {
        private let editor = Editor()
        
        required init(coder: NSCoder) { super.init(coder: coder) }
        override init(textCell: String) {
            super.init(textCell: textCell)
            truncatesLastVisibleLine = true
        }
        
        override func draw(withFrame: NSRect, in view: NSView) {
            super.drawInterior(withFrame: withFrame, in: view)
        }
        
        override func drawInterior(withFrame: NSRect, in: NSView) { }
        
        override func drawingRect(forBounds: NSRect) -> NSRect {
            super.drawingRect(forBounds: forBounds
                                .text)
        }
        
        override func fieldEditor(for: NSView) -> NSTextView? {
            editor
        }
        
        override func focusRingMaskBounds(forFrame: NSRect, in: NSView) -> NSRect {
            controlView
                .flatMap {
                    $0.superview.map(forFrame.ring(superview:))
                } ?? .zero
        }
        
        override func drawFocusRingMask(withFrame: NSRect, in: NSView) {
            NSBezierPath(roundedRect: controlView
                .flatMap {
                    $0.superview.map(withFrame.ring(superview:))
                } ?? .zero, xRadius: 8, yRadius: 8).fill()
        }
    }
}

private extension NSRect {
    var text: Self {
        insetBy(dx: -8, dy: 0)
            .offsetBy(dx: 0, dy: -1)
    }
    
    func ring(superview: NSView) -> Self {
        .init(x: minX - 30.5, y: minY + 0.25, width: superview.frame.width + 10, height: height - 1.5)
    }
}
