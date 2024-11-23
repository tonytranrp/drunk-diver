import SceneKit
import AppKit

class GameViewController: NSViewController {
    // Core components
    private var ship: SCNNode!
    private var scene: SCNScene!
    private var scnView: SCNView!
    
    // State management
    private var isPaused = false
    private var velocity = SCNVector3Zero
    
    // UI components
    private var pauseMenu: PauseMenu?
    private var customCursor: NSView?
    private var notificationView: NSView?
    private var textField: NSTextField!
    
    // Managers
    private var cursorManager: CursorManager!
    
    // Configuration
    private let acceleration = MathUtils.acceleration
    private let drag = MathUtils.drag
    private var lastMousePosition: CGPoint = .zero
    
    
    //Youtube menu thing:)
    private var musicControlView: MusicControlView?

    private func setupMusicControl() {
        musicControlView = MusicControlView(frame: NSRect(x: 10, y: 10, width: 300, height: 400))
        if let musicView = musicControlView {
            musicView.isHidden = true
            view.addSubview(musicView)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        setupGame()
        setupGameLoop()
        setupMusicControl()
        
        // Add mouse moved monitoring
        NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event)
            return event
        }
    }
    private func handleMouseMoved(_ event: NSEvent) {
            guard !isPaused else { return }
            
            let point = view.convert(event.locationInWindow, from: nil)
            
            // Calculate delta from center for rotation
            let centerX = view.bounds.midX
            let centerY = view.bounds.midY
            let deltaX = point.x - centerX
            let deltaY = point.y - centerY
            
            // Rotate ship based on distance from center
            ship.eulerAngles.y -= CGFloat(deltaX) * 0.001
            ship.eulerAngles.x += CGFloat(deltaY) * 0.001
            
            // Keep cursor centered if locked
            if cursorManager.isLocked {
                let centerPoint = view.convert(CGPoint(x: centerX, y: centerY), to: nil)
                CGWarpMouseCursorPosition(centerPoint)
            }
            
            // Update custom cursor position
            updateCursorPosition(point)
            lastMousePosition = point
    }
    override func loadView() {
            // Create the SCNView
            self.view = SCNView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    private func setupGame() {
            // Configure View first
            scnView = self.view as! SCNView
            
            // Setup Scene
            scene = SetupUtils.createScene()
            scene.rootNode.addChildNode(SetupUtils.createGround())
            
            // Setup Ship
            ship = SetupUtils.createShip()
            scene.rootNode.addChildNode(ship)
            
            // Configure Scene View
            SetupUtils.configureSceneView(scnView, scene: scene)
            
            // Setup Cursor
            cursorManager = CursorManager(view: view)
            setupCustomCursor()
            
            // Setup UI
            setupPauseMenu()
            setupControls()
            
            // Initial state
            cursorManager.lockCursor()
    }
    
    private func setupGameLoop() {
        let gameLoop = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.updateGame()
        }
        RunLoop.current.add(gameLoop, forMode: .common)
    }
    
    private func setupCustomCursor() {
        customCursor = UIUtils.createCustomCursor(size: 16)
        if let cursor = customCursor {
            view.addSubview(cursor)
            cursor.isHidden = true
        }
    }
    
    private func updateCursorPosition(_ point: CGPoint) {
        guard let cursor = customCursor else { return }
        let cursorSize = cursor.frame.size
        cursor.frame.origin = CGPoint(
            x: point.x - cursorSize.width/2,
            y: point.y - cursorSize.height/2
        )
    }
    
    private func setupControls() {
        // Key Down Events
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event)
            return event
        }
        
        // Key Up Events
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.togglePauseMenu()
                return nil
            }
            return event
        }
        
        // Mouse Movement
        NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self, !self.isPaused else { return event }
            
            let point = self.view.convert(event.locationInWindow, from: nil)
            self.handleMouseMovement(at: point)
            
            return event
        }
    }
    
    private func handleMouseMovement(at point: CGPoint) {
        // Calculate rotation
        let centerX = view.bounds.midX
        let centerY = view.bounds.midY
        let deltaX = point.x - centerX
        let deltaY = point.y - centerY
        
        // Apply rotation
        ship.eulerAngles.y -= CGFloat(deltaX) * 0.001
        ship.eulerAngles.x += CGFloat(deltaY) * 0.001
        
        // Update cursor
        if cursorManager.isLocked {
            let centerPoint = view.convert(CGPoint(x: centerX, y: centerY), to: nil)
            CGWarpMouseCursorPosition(centerPoint)
        }
        
        updateCursorPosition(point)
        lastMousePosition = point
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        guard !isPaused else { return }
        
        let movement: SCNVector3
        switch event.characters?.lowercased() {
        case "w":
            movement = MathUtils.createVector3(0, 0, -acceleration)
        case "s":
            movement = MathUtils.createVector3(0, 0, acceleration)
        case "a":
            movement = MathUtils.createVector3(-acceleration, 0, 0)
        case "d":
            movement = MathUtils.createVector3(acceleration, 0, 0)
        // Add a key handler for toggling music view (e.g., M key)

        default:
            return
        }
        
        ship.position = MathUtils.calculateNewPosition(current: ship.position, delta: movement)
    }
    
    private func updateGame() {
        guard !isPaused else { return }
        ship.position = MathUtils.applyDrag(to: ship.position, factor: drag)
    }
    
    private func togglePauseMenu() {
        isPaused = !isPaused
        pauseMenu?.isHidden = !isPaused
        customCursor?.isHidden = isPaused
        
        if isPaused {
            cursorManager.unlockCursor()
            self.textField?.becomeFirstResponder()  // Make sure we're using the correct text field reference
        } else {
            cursorManager.lockCursor()
            updateCursorPosition(lastMousePosition)
        }
    }

    private func setupPauseMenu() {
        pauseMenu = PauseMenu(frame: view.bounds, onContinue: { [weak self] in
            self?.continueGame()
        })
        
        if let menu = pauseMenu {
            // Set the text field reference
            self.textField = menu.inputTextField
            // Set the delegate
            self.textField.delegate = self
            menu.isHidden = true
            view.addSubview(menu)
        }
       
        
    }
    
    private func showNotification(text: String) {
        // Remove existing notification
        notificationView?.removeFromSuperview()
        
        // Create new notification
        let notification = UIUtils.createNotificationView(text: text, size: CGSize(width: 300, height: 60))
        
        // Position notification
        notification.frame.origin = CGPoint(
            x: (view.bounds.width - notification.frame.width) / 2,
            y: view.bounds.height - notification.frame.height - 20
        )
        
        view.addSubview(notification)
        notificationView = notification
        
        // Animate
        notification.alphaValue = 0
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            notification.animator().alphaValue = 1
        }, completionHandler: {
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
    
    @objc private func continueGame() {
        isPaused = false
        pauseMenu?.isHidden = true
        customCursor?.isHidden = false
        cursorManager.lockCursor()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        cursorManager.updateTracking()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - NSTextFieldDelegate
extension GameViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            let text = control.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { return true }
            
            if text.contains("youtube.com/") || text.contains("youtu.be/") {
                showNotification(text: "Downloading video...")
                
                YoutubeManager.shared.downloadVideo(from: text) { [weak self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let track):
                            self?.showNotification(text: "Downloaded: \(track.title)")
                            if let musicView = self?.musicControlView {
                                musicView.updateTracks()
                            }
                        case .failure(let error):
                            self?.showNotification(text: "Error: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                showNotification(text: text)
            }
            control.stringValue = ""
            return true
        }
        return false
    }
}
