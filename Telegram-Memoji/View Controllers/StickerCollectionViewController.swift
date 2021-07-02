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
    private lazy var shouldPresentStickerInput
        = (stickerSet?.stickers?.count == 0)
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldPresentStickerInput {
            presentStickerInputViewController()
            shouldPresentStickerInput = false
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
        
        stickerInputVC.context = stickerSet?.managedObjectContext
        stickerInputVC.configure {
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
    private static let reuseIdentifier = "StickerCell"
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int { stickerSet?.stickers?.count ?? 0 }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.reuseIdentifier,
            for: indexPath) as! StickerImageCell
        
        guard indexPath.section == 0 else { return cell }
        
        if let sticker = stickerSet?.stickers?
            .object(at: indexPath.item) as? Sticker,
           let imageData = sticker.imageData,
           let image = UIImage(data: imageData)
        { cell.imageView.image = image }
        
        return cell
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

// MARK: - StickerImageCell

final class StickerImageCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
}
