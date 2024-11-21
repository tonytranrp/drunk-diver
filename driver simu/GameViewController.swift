import SceneKit
import QuartzCore
import AppKit

class GameViewController: NSViewController {// Add these properties at the top of your class
    private var isCursorLocked = false
    private var cursorTrackingArea: NSTrackingArea?
    private var ship: SCNNode!
    private var isPaused = false
    private var pauseMenu: NSVisualEffectView?
    private var velocity = SCNVector3Zero
    private let acceleration: CGFloat = 0.5
    private let drag: CGFloat = 0.98
    private var textField: NSTextField!
    private var notificationView: NSView?
    private var customCursor: NSView?
    private var lastMousePosition: CGPoint = .zero
    private func setupCursorLocking() {
            // Remove existing tracking area if any
            if let existingTrackingArea = cursorTrackingArea {
                view.removeTrackingArea(existingTrackingArea)
            }
            
            // Create new tracking area
            let trackingArea = NSTrackingArea(
                rect: view.bounds,
                options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited],
                owner: self,
                userInfo: nil
            )
            view.addTrackingArea(trackingArea)
            cursorTrackingArea = trackingArea
        }
        
        // Add this method to handle cursor locking
        private func lockCursor() {
            guard !isPaused else { return }
            
            isCursorLocked = true
            NSCursor.hide()
            
            // Get the center point of the view
            let centerX = view.bounds.midX
            let centerY = view.bounds.midY
            let centerPoint = view.convert(CGPoint(x: centerX, y: centerY), to: nil)
            
            // Move cursor to center
            CGWarpMouseCursorPosition(centerPoint)
            
            // Confine cursor to the center of the view
            CGAssociateMouseAndMouseCursorPosition(0)
        }
        
        // Add this method to handle cursor unlocking
        private func unlockCursor() {
            isCursorLocked = false
            NSCursor.unhide()
            CGAssociateMouseAndMouseCursorPosition(1)
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        setupControls()
        setupPauseMenu()
        setupCustomCursor()
        setupCursorLocking() // Add this line
        
        // Start with cursor locked
        lockCursor()
        
        let gameLoop = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
        RunLoop.current.add(gameLoop, forMode: .common)
    }
    // Add window resize handler
    override func viewDidLayout() {
        super.viewDidLayout()
        setupCursorLocking() // Update tracking area when view size changes
    }
    
    private func setupCustomCursor() {
        // Create a custom cursor view
        let cursorSize: CGFloat = 16
        let cursorView = NSView(frame: NSRect(x: 0, y: 0, width: cursorSize, height: cursorSize))
        cursorView.wantsLayer = true
        
        // Create crosshair shape
        let crosshairLayer = CAShapeLayer()
        let path = NSBezierPath()
        
        // Horizontal line
        path.move(to: NSPoint(x: 0, y: cursorSize/2))
        path.line(to: NSPoint(x: cursorSize, y: cursorSize/2))
        
        // Vertical line
        path.move(to: NSPoint(x: cursorSize/2, y: 0))
        path.line(to: NSPoint(x: cursorSize/2, y: cursorSize))
        
        // Outer circle
        path.appendOval(in: NSRect(x: 2, y: 2, width: cursorSize-4, height: cursorSize-4))
        
        crosshairLayer.path = path.cgPath
        crosshairLayer.strokeColor = NSColor.white.cgColor
        crosshairLayer.fillColor = nil
        crosshairLayer.lineWidth = 1.0
        
        // Add glow effect
        crosshairLayer.shadowColor = NSColor.white.cgColor
        crosshairLayer.shadowOffset = CGSize.zero
        crosshairLayer.shadowRadius = 2
        crosshairLayer.shadowOpacity = 0.8
        
        cursorView.layer?.addSublayer(crosshairLayer)
        view.addSubview(cursorView)
        customCursor = cursorView
        
        // Initially hide the custom cursor
        customCursor?.isHidden = true
    }
    
    private func updateCursorPosition(_ point: CGPoint) {
        guard let cursor = customCursor else { return }
        let cursorSize = cursor.frame.size
        cursor.frame.origin = CGPoint(
            x: point.x - cursorSize.width/2,
            y: point.y - cursorSize.height/2
        )
    }
    
    private func setupScene() {
        let scene = SCNScene()
        
        // Camera setup
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 15)
        scene.rootNode.addChildNode(cameraNode)
        
        // Lighting
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // Ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Ground plane
        let groundGeometry = SCNFloor()
        groundGeometry.reflectivity = 0.2
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = NSColor.gray
        groundGeometry.materials = [groundMaterial]
        let groundNode = SCNNode(geometry: groundGeometry)
        groundNode.position = SCNVector3(x: 0, y: -2, z: 0)
        scene.rootNode.addChildNode(groundNode)
        
        // Ship setup
        if let shipScene = SCNScene(named: "art.scnassets/ship.scn"),
           let shipNode = shipScene.rootNode.childNode(withName: "ship", recursively: true) {
            ship = shipNode
            ship.position = SCNVector3Zero
            scene.rootNode.addChildNode(ship)
        } else {
            // If we can't load the ship model, create a temporary cube
            let shipGeometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
            let shipMaterial = SCNMaterial()
            shipMaterial.diffuse.contents = NSColor.blue
            shipGeometry.materials = [shipMaterial]
            ship = SCNNode(geometry: shipGeometry)
            ship.position = SCNVector3Zero
            scene.rootNode.addChildNode(ship)
        }
        
        let scnView = self.view as! SCNView
        scnView.scene = scene
        scnView.allowsCameraControl = false  // Disable default camera control
        scnView.showsStatistics = true
        scnView.backgroundColor = NSColor.black
    }
    
    private func setupControls() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return event
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.togglePauseMenu()
                return nil
            }
            return event
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return event }
            
            if !self.isPaused {
                let point = self.view.convert(event.locationInWindow, from: nil)
                
                // Calculate delta from center for rotation
                let centerX = self.view.bounds.midX
                let centerY = self.view.bounds.midY
                let deltaX = point.x - centerX
                let deltaY = point.y - centerY
                
                // Rotate ship based on mouse movement
                self.ship.eulerAngles.y -= CGFloat(deltaX) * 0.001
                self.ship.eulerAngles.x += CGFloat(deltaY) * 0.001
                
                // Keep cursor centered if locked
                if self.isCursorLocked {
                    let centerPoint = self.view.convert(CGPoint(x: centerX, y: centerY), to: nil)
                    CGWarpMouseCursorPosition(centerPoint)
                }
                
                // Update custom cursor position
                self.updateCursorPosition(point)
            }
            
            return event
        }
    }
    
    private func setupPauseMenu() {
        // Create a visual effect view for the blur effect that covers the entire view
        let menuView = NSVisualEffectView(frame: view.bounds)
        menuView.autoresizingMask = [.width, .height]  // Make it resize with the window
        menuView.blendingMode = .behindWindow
        menuView.material = .dark
        menuView.state = .active
        menuView.wantsLayer = true
        
        // Add a semi-transparent overlay with glow that covers the entire view
        let overlayView = NSView(frame: menuView.bounds)
        overlayView.autoresizingMask = [.width, .height]  // Make overlay resize with the window
        overlayView.wantsLayer = true
        overlayView.layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.3).cgColor
        
        // Create a container for the menu items that stays centered
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        
        // Create text field with glowing effect
        textField = NSTextField(frame: NSRect(x: 0, y: 100, width: 300, height: 40))
        textField.placeholderString = "Type here..."
        textField.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        textField.textColor = NSColor.white
        textField.isBezeled = false
        textField.drawsBackground = true
        textField.font = NSFont.systemFont(ofSize: 16)
        textField.delegate = self
        
        // Add glowing effect to text field
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 8
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor.white.withAlphaComponent(0.5).cgColor
        textField.layer?.shadowColor = NSColor.white.cgColor
        textField.layer?.shadowOffset = CGSize.zero
        textField.layer?.shadowRadius = 10
        textField.layer?.shadowOpacity = 0.3
        
        // Create continue button with glow effect
        let continueButton = NSButton(frame: NSRect(x: 0, y: 40, width: 300, height: 40))
        continueButton.title = "Continue"
        continueButton.bezelStyle = .rounded
        continueButton.wantsLayer = true
        continueButton.layer?.backgroundColor = NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.8).cgColor
        continueButton.layer?.cornerRadius = 8
        continueButton.layer?.shadowColor = NSColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0).cgColor
        continueButton.layer?.shadowOffset = CGSize.zero
        continueButton.layer?.shadowRadius = 15
        continueButton.layer?.shadowOpacity = 0.6
        continueButton.target = self
        continueButton.action = #selector(continueGame)
        
        // Add all elements to the container
        containerView.addSubview(textField)
        containerView.addSubview(continueButton)
        
        // Add all views to the menu
        menuView.addSubview(overlayView)
        menuView.addSubview(containerView)
        
        // Setup constraints to keep container centered
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: menuView.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: menuView.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        menuView.isHidden = true
        view.addSubview(menuView)
        pauseMenu = menuView
        
        // Add notification when window resizes
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(windowDidResize),
                                             name: NSWindow.didResizeNotification,
                                             object: nil)
    }

    // Add this method to handle window resizing
    @objc private func windowDidResize(_ notification: Notification) {
        // Update the menu view frame to match the new window size
        pauseMenu?.frame = view.bounds
    }

    // Don't forget to remove the observer when the view controller is deallocated
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func showNotification(text: String) {
        // Remove existing notification if any
        notificationView?.removeFromSuperview()
        
        // Create notification view
        let notification = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 60))
        notification.wantsLayer = true
        notification.layer?.backgroundColor = NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.9).cgColor
        notification.layer?.cornerRadius = 12
        notification.layer?.shadowColor = NSColor.white.cgColor
        notification.layer?.shadowOffset = CGSize.zero
        notification.layer?.shadowRadius = 20
        notification.layer?.shadowOpacity = 0.4
        
        // Add text label
        let label = NSTextField(frame: NSRect(x: 20, y: 20, width: 260, height: 20))
        label.stringValue = text
        label.textColor = NSColor.white
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        
        notification.addSubview(label)
        
        // Position notification at top of screen
        notification.frame.origin = CGPoint(
            x: (view.bounds.width - notification.frame.width) / 2,
            y: view.bounds.height - notification.frame.height - 20
        )
        
        view.addSubview(notification)
        notificationView = notification
        
        // Animate notification
        notification.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            notification.animator().alphaValue = 1
        }, completionHandler: {
            // Fade out after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    notification.animator().alphaValue = 0
                }, completionHandler: {
                    notification.removeFromSuperview()
                    self.notificationView = nil
                })
            }
        })
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        guard !isPaused else { return }
        
        switch event.characters?.lowercased() {
        case "w":
            ship.position = SCNVector3(
                ship.position.x,
                ship.position.y,
                ship.position.z - CGFloat(acceleration)
            )
        case "s":
            ship.position = SCNVector3(
                ship.position.x,
                ship.position.y,
                ship.position.z + CGFloat(acceleration)
            )
        case "a":
            ship.position = SCNVector3(
                ship.position.x - CGFloat(acceleration),
                ship.position.y,
                ship.position.z
            )
        case "d":
            ship.position = SCNVector3(
                ship.position.x + CGFloat(acceleration),
                ship.position.y,
                ship.position.z
            )
        default:
            break
        }
    }
    
    private func updateGame() {
        guard !isPaused, let ship = self.ship else { return }
        
        ship.position = SCNVector3(
            ship.position.x * CGFloat(drag),
            ship.position.y,
            ship.position.z * CGFloat(drag)
        )
    }
    
    private func togglePauseMenu() {
        isPaused = !isPaused
        pauseMenu?.isHidden = !isPaused
        customCursor?.isHidden = isPaused
        
        if isPaused {
            unlockCursor()
            textField.becomeFirstResponder()
        } else {
            lockCursor()
            updateCursorPosition(lastMousePosition)
        }
    }
    
    @objc private func continueGame() {
        isPaused = false
        pauseMenu?.isHidden = true
        customCursor?.isHidden = false
        lockCursor()
    }
}

// MARK: - NSTextFieldDelegate
extension GameViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            let text = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                showNotification(text: text)
                textField.stringValue = ""
            }
            return true
        }
        return false
    }
}


extension NSView {
    var center: CGPoint {
        get {
            return CGPoint(x: frame.midX, y: frame.midY)
        }
        set {
            frame.origin = CGPoint(
                x: newValue.x - frame.width / 2,
                y: newValue.y - frame.height / 2
            )
        }
    }
}
