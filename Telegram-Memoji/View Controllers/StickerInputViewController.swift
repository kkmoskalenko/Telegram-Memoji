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
            if let image = stickerImage {
                print(image.description)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pasteConfiguration = UIPasteConfiguration(
            forAccepting: UIImage.self)
        
        let inputModeNotification = UITextInputMode
            .currentInputModeDidChangeNotification
        NotificationCenter.default.addObserver(
            self, selector: #selector(inputModeDidChange),
            name: inputModeNotification, object: nil)
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

// MARK: - Action Handlers

extension StickerInputViewController {
    @objc private func inputModeDidChange() {
        guard isFirstResponder else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.reloadInputViews()
        }
    }
}
