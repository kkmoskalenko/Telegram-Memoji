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
            navigationItem.rightBarButtonItem?
                .isEnabled = hasImage
            
            Self.selectionGenerator.selectionChanged()
            
            UIView.transition(with: view, duration: 0.2, options: [
                .transitionCrossDissolve, .curveEaseOut
            ]) {
                self.keyboardTipsView.isHidden = hasImage
                self.imageView.isHidden = !hasImage
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
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var keyboardTipsView: UIScrollView!
    @IBOutlet private var keyboardTipsTitleLabel: UILabel!
}

// MARK: - View Life Cycle

extension StickerInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.delegate = self
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _canResignFirstResponder = true
        resignFirstResponder()
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
    var hasText: Bool { false }
    
    func insertText(_ text: String) {
        
    }
    
    func deleteBackward() {
        
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

// MARK: - UINavigationControllerDelegate

extension StickerInputViewController: UINavigationControllerDelegate {
    func navigationControllerSupportedInterfaceOrientations(
        _ navigationController: UINavigationController
    ) -> UIInterfaceOrientationMask { .portrait }
}

// MARK: - Feedback Generators

extension StickerInputViewController {
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()
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
            sticker.imageData = image.pngData()
            sticker.emojis = ""
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
