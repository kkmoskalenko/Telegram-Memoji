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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldPresentStickerPicker {
            presentStickerInputViewController()
            shouldPresentStickerPicker = false
        }
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
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.visibleCells.forEach {
            if let cell = $0 as? StickerImageCell {
                cell.setEditing(editing, animated: animated)
            }
        }
        if !editing {
            Self.managedObjectContext.saveIfNeeded()
        }
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
            
            Self.managedObjectContext.saveIfNeeded()
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
    
    @objc private func deleteSticker(_ sender: UIButton) {
        guard let cell = sender.superview?.superview as? StickerImageCell,
              let indexPath = collectionView.indexPath(for: cell)
        else { return }
        
        let index = indexPath.item - 1
        if let sticker = stickerSet?.stickers?
            .object(at: index) as? Sticker
        {
            stickerSet?.removeFromStickers(sticker)
            Self.managedObjectContext.delete(sticker)
            
            collectionView.deleteItems(at: [indexPath])
        }
    }
    
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
        {
            cell.imageView.image = image
            cell.setEditing(isEditing, animated: false)
            cell.deleteButton.addTarget(
                self, action: #selector(deleteSticker),
                for: .touchUpInside)
        }
        
        return cell
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        canMoveItemAt indexPath: IndexPath
    ) -> Bool { isEditing && (indexPath.item != 0) }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        moveItemAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        let sourceIndex = sourceIndexPath.item - 1
        let destinationIndex = destinationIndexPath.item - 1
        
        if let sticker = stickerSet?.stickers?
            .object(at: sourceIndex) as? Sticker
        {
            stickerSet?.removeFromStickers(at: sourceIndex)
            stickerSet?.insertIntoStickers(sticker, at: destinationIndex)
        }
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
    
    override func collectionView(
        _ collectionView: UICollectionView,
        targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath,
        toProposedIndexPath proposedIndexPath: IndexPath
    ) -> IndexPath {
        proposedIndexPath.item == 0 ?
            originalIndexPath : proposedIndexPath
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
    @IBOutlet var deleteButton: UIButton!
    
    func setEditing(_ editing: Bool, animated: Bool) {
        let animations = { self.deleteButton.isHidden = !editing }
        if editing { startShaking() } else { stopShaking() }
        
        if animated { UIView.transition(
            with: self, duration: 0.2,
            options: .transitionCrossDissolve,
            animations: animations
        ) } else { animations() }
    }
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
