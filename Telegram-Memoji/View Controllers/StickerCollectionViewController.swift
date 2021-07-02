//
//  StickerCollectionViewController.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 30.06.2021.
//

import UIKit

final class StickerCollectionViewController: UICollectionViewController {
    var stickerSet: StickerSet?
    
    private var cellSize = CGSize.zero
    private lazy var shouldPresentStickerPicker = (stickerSet == nil)
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldPresentStickerPicker {
            presentStickerInputViewController()
            shouldPresentStickerPicker = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Self.managedObjectContext.saveIfNeeded()
    }
    
    override func viewWillTransition(
        to size: CGSize, with coordinator:
            UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)
        collectionViewLayout.invalidateLayout()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        cellSize = calculateCellSize()
    }
}

// MARK: - Performing a Segue

extension StickerCollectionViewController {
    private static let segueIdentifier = "PresentStickerInputViewControllerSegue"
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard
            segue.identifier == Self.segueIdentifier,
            let destinationNavigationController =
                segue.destination as? UINavigationController,
            let stickerInputVC = destinationNavigationController
                .topViewController as? StickerInputViewController
        else { return }
        
        stickerInputVC.configure {
            if self.stickerSet == nil {
                let context = Self.managedObjectContext
                self.stickerSet = StickerSet(context: context)
            }
            
            self.stickerSet?.editDate = Date()
            self.stickerSet?.addToStickers($0)
            self.collectionView.reloadData()
        }
    }
    
    private func presentStickerInputViewController() {
        if UITextInputMode.isEmojiEnabled {
            performSegue(withIdentifier: Self.segueIdentifier, sender: nil)
        } else {
            // TODO: Replace preconditionFailure with an alert
            preconditionFailure("Emoji keyboard is not enabled.")
        }
    }
}

// MARK: - UICollectionViewDataSource

extension StickerCollectionViewController {
    private static let stickerCellReuseIdentifier = "StickerCell"
    private static let addButtonReuseIdentifier = "AddButtonCell"
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        let stickerCount = stickerSet?.stickers?.count
        return (stickerCount ?? 0) + 1
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.addButtonReuseIdentifier,
                for: indexPath) as! AddButtonCell
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.stickerCellReuseIdentifier,
            for: indexPath) as! StickerImageCell
        
        if let sticker = stickerSet?.stickers?
            .object(at: indexPath.item - 1) as? Sticker,
           let imageData = sticker.imageData,
           let image = UIImage(data: imageData)
        { cell.imageView.image = image }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension StickerCollectionViewController {
    override func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard indexPath.item == 0 else { return }
        presentStickerInputViewController()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension StickerCollectionViewController: UICollectionViewDelegateFlowLayout {
    private static let cellSpacing: CGFloat = 16
    private static let widthThreshold: CGFloat = 760
    
    private func calculateCellSize() -> CGSize {
        let visibleWidth = collectionView.visibleSize.width
        let safeAreaInsets = collectionView.safeAreaInsets
        
        let itemsPerRow: CGFloat = visibleWidth
            >= Self.widthThreshold ? 6 : 3
        
        let paddingSpace = Self.cellSpacing * (itemsPerRow + 1)
        let availableWidth = visibleWidth - paddingSpace
            - (safeAreaInsets.left + safeAreaInsets.right)
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize { cellSize }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets { UIEdgeInsets(
        top: Self.cellSpacing, left: Self.cellSpacing,
        bottom: Self.cellSpacing, right: Self.cellSpacing
    ) }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat { Self.cellSpacing }
}

// MARK: - Collection View Cells

final class StickerImageCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
}

final class AddButtonCell: UICollectionViewCell {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        layer.masksToBounds = true
        layer.backgroundColor = tintColor
            .withAlphaComponent(0.15).cgColor
        layer.borderColor = tintColor
            .withAlphaComponent(0.25).cgColor
        layer.borderWidth = 1
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = 0.5 * bounds.width
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        alpha = 1
        UIView.animate(
            withDuration: 0.35, delay: 0,
            options: .curveLinear
        ) { self.alpha = 0.5 }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        alpha = 0.5
        UIView.animate(
            withDuration: 0.35, delay: 0,
            options: .curveLinear
        ) { self.alpha = 1 }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        alpha = 0.5
        UIView.animate(
            withDuration: 0.35, delay: 0,
            options: .curveLinear
        ) { self.alpha = 1 }
    }
}
