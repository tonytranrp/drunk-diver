import AppKit

class CursorManager: NSObject {
    private var isCursorLocked = false
    private var cursorTrackingArea: NSTrackingArea?
    private weak var view: NSView?
    
    init(view: NSView) {
        self.view = view
        super.init()
        setupTracking()
    }
    
    private func setupTracking() {
        guard let view = view else { return }
        
        if let existingTrackingArea = cursorTrackingArea {
            view.removeTrackingArea(existingTrackingArea)
        }
        
        let trackingArea = NSTrackingArea(
            rect: view.bounds,
            options: [.activeAlways, .mouseMoved],  // Removed .mouseEnteredAndExited
            owner: view,  // Changed owner to view instead of self
            userInfo: nil
        )
        view.addTrackingArea(trackingArea)
        cursorTrackingArea = trackingArea
    }
    
    func lockCursor() {
        isCursorLocked = true
        NSCursor.hide()
        
        guard let view = view else { return }
        let centerX = view.bounds.midX
        let centerY = view.bounds.midY
        let centerPoint = view.convert(CGPoint(x: centerX, y: centerY), to: nil)
        
        CGWarpMouseCursorPosition(centerPoint)
        CGAssociateMouseAndMouseCursorPosition(0)
    }
    
    func unlockCursor() {
        isCursorLocked = false
        NSCursor.unhide()
        CGAssociateMouseAndMouseCursorPosition(1)
    }
    
    func updateTracking() {
        setupTracking()
    }
    
    var isLocked: Bool {
        return isCursorLocked
    }
}
