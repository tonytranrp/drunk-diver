import AppKit

class PauseMenu: NSVisualEffectView {
    private var textField: NSTextField!
    private var continueButton: NSButton!
    private var onContinue: (() -> Void)?
    weak var delegate: NSTextFieldDelegate?
    
    init(frame: NSRect, onContinue: @escaping () -> Void) {
        super.init(frame: frame)
        self.onContinue = onContinue
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        autoresizingMask = [.width, .height]
        blendingMode = .behindWindow
        material = .dark
        state = .active
        wantsLayer = true
        
        setupOverlay()
        setupContainer()
    }
    
    private func setupOverlay() {
        let overlayView = NSView(frame: bounds)
        overlayView.autoresizingMask = [.width, .height]
        overlayView.wantsLayer = true
        overlayView.layer?.backgroundColor = NSColor(white: 0.0, alpha: 0.3).cgColor
        addSubview(overlayView)
    }
    
    private func setupContainer() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 300),
            container.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        setupTextField(in: container)
        setupContinueButton(in: container)
    }
    
    private func setupTextField(in container: NSView) {
        textField = NSTextField(frame: NSRect(x: 0, y: 100, width: 300, height: 40))
        textField.placeholderString = "Type here..."
        textField.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        textField.textColor = NSColor.white
        textField.isBezeled = false
        textField.drawsBackground = true
        textField.font = NSFont.systemFont(ofSize: 16)
        textField.delegate = delegate
        
        // Add text field styling
        textField.wantsLayer = true
        textField.layer?.cornerRadius = 8
        textField.layer?.borderWidth = 1
        textField.layer?.borderColor = NSColor.white.withAlphaComponent(0.5).cgColor
        textField.layer?.shadowColor = NSColor.white.cgColor
        textField.layer?.shadowOffset = CGSize.zero
        textField.layer?.shadowRadius = 10
        textField.layer?.shadowOpacity = 0.3
        
        container.addSubview(textField)
    }
    
    private func setupContinueButton(in container: NSView) {
        continueButton = NSButton(frame: NSRect(x: 0, y: 40, width: 300, height: 40))
        continueButton.title = "Continue"
        continueButton.bezelStyle = .rounded
        continueButton.target = self
        continueButton.action = #selector(continuePressed)
        
        UIUtils.styleButton(continueButton, withColor: NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.8))
        container.addSubview(continueButton)
    }
    
    @objc private func continuePressed() {
        onContinue?()
    }
    
    func focusTextField() {
        textField.becomeFirstResponder()
    }
    // Add this getter
    var inputTextField: NSTextField {
        return textField
    }
}
