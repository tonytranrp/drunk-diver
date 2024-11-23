import AppKit

class UIUtils {
    // TextField styling
    static func styleTextField(_ textField: NSTextField) {
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 8
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor.white.withAlphaComponent(0.5).cgColor
        textField.layer?.shadowColor = NSColor.white.cgColor
        textField.layer?.shadowOffset = CGSize.zero
        textField.layer?.shadowRadius = 10
        textField.layer?.shadowOpacity = 0.3
    }
    
    // Button styling
    static func styleButton(_ button: NSButton, withColor color: NSColor) {
        button.wantsLayer = true
        button.layer?.backgroundColor = color.cgColor
        button.layer?.cornerRadius = 8
        button.layer?.shadowColor = color.cgColor
        button.layer?.shadowOffset = CGSize.zero
        button.layer?.shadowRadius = 15
        button.layer?.shadowOpacity = 0.6
    }
    
    // Cursor creation
    static func createCustomCursor(size: CGFloat) -> NSView {
        let cursorView = NSView(frame: NSRect(x: 0, y: 0, width: size, height: size))
        cursorView.wantsLayer = true
        
        let crosshairLayer = CAShapeLayer()
        let path = NSBezierPath()
        
        // Crosshair shape
        path.move(to: NSPoint(x: 0, y: size/2))
        path.line(to: NSPoint(x: size, y: size/2))
        path.move(to: NSPoint(x: size/2, y: 0))
        path.line(to: NSPoint(x: size/2, y: size))
        path.appendOval(in: NSRect(x: 2, y: 2, width: size-4, height: size-4))
        
        crosshairLayer.path = path.cgPath
        crosshairLayer.strokeColor = NSColor.white.cgColor
        crosshairLayer.fillColor = nil
        crosshairLayer.lineWidth = 1.0
        crosshairLayer.shadowColor = NSColor.white.cgColor
        crosshairLayer.shadowOffset = CGSize.zero
        crosshairLayer.shadowRadius = 2
        crosshairLayer.shadowOpacity = 0.8
        
        cursorView.layer?.addSublayer(crosshairLayer)
        return cursorView
    }
    
    // Notification view creation
    static func createNotificationView(text: String, size: CGSize) -> NSView {
        let notification = NSView(frame: NSRect(x: 0, y: 0, width: size.width, height: size.height))
        notification.wantsLayer = true
        notification.layer?.backgroundColor = NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.9).cgColor
        notification.layer?.cornerRadius = 12
        notification.layer?.shadowColor = NSColor.white.cgColor
        notification.layer?.shadowOffset = CGSize.zero
        notification.layer?.shadowRadius = 20
        notification.layer?.shadowOpacity = 0.4
        
        let label = NSTextField(frame: NSRect(x: 20, y: 20, width: size.width - 40, height: 20))
        label.stringValue = text
        label.textColor = NSColor.white
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        
        notification.addSubview(label)
        return notification
    }
}
