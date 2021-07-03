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
    
    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No Stickers"
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()
    
    // MARK: IB Outlets
    
    @IBOutlet private var newStickerButton: UIButton!
    @IBOutlet private var uploadButton: UIBarButtonItem!
}

// MARK: - UIViewController Overrides

extension StickerCollectionViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldPresentStickerPicker {
            presentStickerInputViewController()
            shouldPresentStickerPicker = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = false
        configureToolbarItems()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isToolbarHidden = true
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
        
        let stickerCount = stickerSet?.stickers?.count ?? 0
        collectionView.backgroundView =
            (stickerCount == 0) ? emptyLabel : nil
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        navigationItem.setHidesBackButton(editing, animated: false)
        navigationController?.navigationBar.setNeedsLayout()
        
        newStickerButton.isEnabled = !editing
        uploadButton.isEnabled = !editing
        
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
            
            if let index = self.stickerSet?.stickers?.index(of: $0) {
                self.collectionView.insertItems(at: [
                    IndexPath(item: index, section: 0)
                ])
            }
            
            Self.managedObjectContext.saveIfNeeded()
        }
    }
    
    @objc private func presentStickerInputViewController() {
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
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        stickerSet?.stickers?.count ?? 0
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.stickerCellReuseIdentifier,
            for: indexPath) as! StickerImageCell
        
        if let sticker = stickerSet?.stickers?
            .object(at: indexPath.item) as? Sticker,
           let imageData = sticker.imageData,
           let image = UIImage(data: imageData)
        {
            cell.imageView.image = image
            cell.setEditing(isEditing, animated: false)
            
            let action = #selector(deleteSticker(_:))
            cell.deleteButton.addTarget(
                self, action: action, for: .touchUpInside)
        }
        
        return cell
    }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        canMoveItemAt indexPath: IndexPath
    ) -> Bool { isEditing }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        moveItemAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        if let sticker = stickerSet?.stickers?.object(
            at: sourceIndexPath.item) as? Sticker
        {
            stickerSet?.removeFromStickers(at: sourceIndexPath.item)
            stickerSet?.insertIntoStickers(sticker, at: destinationIndexPath.item)
        }
    }
}

// MARK: - UICollectionViewDelegate

extension StickerCollectionViewController {
    override func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint) -> UIContextMenuConfiguration?
    {
        guard !isEditing else { return nil }
        
        if let sticker = stickerSet?.stickers?
            .object(at: indexPath.item) as? Sticker
        {
            let emoji = sticker.emojis?.prefix(1).appending(" ")
            return UIContextMenuConfiguration(
                identifier: nil, previewProvider: nil
            ) { _ in
                UIMenu(title: (emoji ?? "") + "Sticker", children: [
                    UIAction(title: "Reorder Stickers", image: UIImage(
                        systemName: "arrow.up.arrow.down"
                    )) { _ in self.setEditing(true, animated: true) },
                    UIAction(title: "Remove from Set",
                             image: UIImage(systemName: "trash"),
                             attributes: .destructive
                    ) { _ in self.deleteSticker(at: indexPath) }
                ])
            }
        }
        
        return UIContextMenuConfiguration()
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

// MARK: - Helper Methods

extension StickerCollectionViewController {
    private func configureToolbarItems() {
        if let font = newStickerButton.titleLabel?.font,
           let descriptor = font.fontDescriptor.withDesign(.rounded)
        {
            newStickerButton.titleLabel?.font = UIFont(
                descriptor: descriptor, size: font.pointSize)
        }
        
        let action = #selector(presentStickerInputViewController)
        newStickerButton.addTarget(self, action: action, for: .touchUpInside)
        
        let button = UIBarButtonItem(customView: newStickerButton)
        let spacer = UIBarButtonItem(systemItem: .flexibleSpace)
        
        setToolbarItems([button, spacer, editButtonItem], animated: false)
    }
    
    private func deleteSticker(at indexPath: IndexPath) {
        if let sticker = stickerSet?.stickers?
            .object(at: indexPath.item) as? Sticker
        {
            stickerSet?.removeFromStickers(sticker)
            Self.managedObjectContext.delete(sticker)
            
            collectionView.deleteItems(at: [indexPath])
        }
        
        if let stickerSet = stickerSet,
           (stickerSet.stickers?.count ?? 0) == 0
        {
            Self.managedObjectContext.delete(stickerSet)
            self.stickerSet = nil
        }
    }
    
    @objc private func deleteSticker(_ sender: UIButton) {
        if let cell = sender.superview?.superview as? StickerImageCell,
           let indexPath = collectionView.indexPath(for: cell)
        { deleteSticker(at: indexPath) }
    }
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
