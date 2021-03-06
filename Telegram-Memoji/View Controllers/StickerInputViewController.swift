//
//  StickerInputViewController.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 30.06.2021.
//

import UIKit

final class StickerInputViewController: UIViewController {
    private var _canResignFirstResponder = false
    private var stickerImage: UIImage? {
        didSet {
            let hasImage = (stickerImage != nil)
            Self.selectionGenerator.selectionChanged()
            
            UIView.transition(with: view, duration: 0.2, options: [
                .transitionCrossDissolve, .curveEaseOut
            ]) {
                self.keyboardTipsView.isHidden = hasImage
                self.emojiInputView.isHidden = !hasImage
                self.imageView.image = self.stickerImage
            }
        }
    }
    
    // MARK: Sticker Handler
    
    typealias StickerHandler = (Sticker) -> Void
    private var stickerHandler: StickerHandler?
    
    func configure(_ handler: StickerHandler?) {
        stickerHandler = handler
    }
    
    // MARK: IB Outlets
    
    @IBOutlet private var emojiInputView: UIView!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var emojiLabel: EmojiLabel!
    
    @IBOutlet private var keyboardTipsView: UIScrollView!
    @IBOutlet private var keyboardTipsTitleLabel: UILabel!
}

// MARK: - View Life Cycle

extension StickerInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pasteConfiguration = UIPasteConfiguration(
            forAccepting: UIImage.self)
        
        let inputModeNotification = UITextInputMode
            .currentInputModeDidChangeNotification
        NotificationCenter.default.addObserver(
            self, selector: #selector(inputModeDidChange),
            name: inputModeNotification, object: nil)
        
        keyboardTipsView.bottomAnchor.constraint(
            equalTo: view.keyboardLayoutGuide.topAnchor
        ).isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _canResignFirstResponder = false
        becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.orientationLock = .portrait
        
        let orientation = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(orientation, forKey: "orientation")
        UINavigationController.attemptRotationToDeviceOrientation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        _canResignFirstResponder = true
        resignFirstResponder()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.orientationLock = .all
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !keyboardTipsView.isHidden {
            let offset = keyboardTipsTitleLabel.frame.origin
            keyboardTipsView.setContentOffset(offset, animated: true)
        }
    }
    
    override var disablesAutomaticKeyboardDismissal: Bool { true }
}

// MARK: - UIKeyInput

extension StickerInputViewController: UIKeyInput {
    private var inputValid: Bool {
        hasText && (stickerImage != nil)
    }
    
    var hasText: Bool {
        emojiLabel.characterCount > 0
    }
    
    func insertText(_ text: String) {
        if !emojiInputView.isHidden,
           text.containsOnlyEmoji,
           emojiLabel.characterCount < 5
        { emojiLabel.text?.append(text) }
        
        navigationItem.rightBarButtonItem?
            .isEnabled = inputValid
    }
    
    func deleteBackward() {
        emojiLabel.text?.removeLast()
        navigationItem.rightBarButtonItem?
            .isEnabled = inputValid
    }
}

// MARK: - UIResponder

extension StickerInputViewController {
    override var canBecomeFirstResponder: Bool { true }
    override var canResignFirstResponder: Bool { _canResignFirstResponder }
    override var textInputContextIdentifier: String? { "" }
    override var textInputMode: UITextInputMode? { .emojiInputMode }
}

// MARK: - UIPasteConfigurationSupporting

extension StickerInputViewController {
    /**
     A string that represents the memoji sticker UTI.
     - `com.apple.uikit.image`
     - `public.png`
     - `public.jpeg`
     - `com.apple.png-sticker`
     */
    private static let pngStickerTypeIdentifier = "com.apple.png-sticker"
    
    override func canPaste(_ itemProviders: [NSItemProvider]) -> Bool {
        itemProviders.contains {
            $0.hasItemConformingToTypeIdentifier(
                Self.pngStickerTypeIdentifier)
        }
    }
    
    override func paste(itemProviders: [NSItemProvider]) {
        guard let provider = itemProviders.first(where: {
            $0.hasItemConformingToTypeIdentifier(
                Self.pngStickerTypeIdentifier)
        }) else { return }
        
        provider.loadItem(
            forTypeIdentifier: Self.pngStickerTypeIdentifier
        ) { [weak self] item, error in
            guard error == nil else { return }
            
            if let data = item as? Data,
               let image = UIImage(data: data)
            { DispatchQueue.main.async {
                self?.stickerImage = image
            } }
        }
    }
}

// MARK: - Feedback Generators

extension StickerInputViewController {
    private static let selectionGenerator = UISelectionFeedbackGenerator()
}

// MARK: - Action Handlers

extension StickerInputViewController {
    @objc private func inputModeDidChange() {
        guard isFirstResponder else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.reloadInputViews()
        }
    }
    
    @IBAction func cancelButtonAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func doneButtonAction(_ sender: UIBarButtonItem) {
        if let image = stickerImage {
            let context = Self.managedObjectContext
            let sticker = Sticker(context: context)
            
            let imagePngData = image.resize(
                to: CGSize(width: 512, height: 512)
            ).pngData()
            
            sticker.imageData = imagePngData
            sticker.emojis = emojiLabel.text
            
            stickerHandler?(sticker)
        }
        
        dismiss(animated: true)
    }
    
    @IBAction func showKeyboardButtonAction(_ sender: UIButton) {
        if isFirstResponder {
            reloadInputViews()
        } else {
            becomeFirstResponder()
        }
    }
}
