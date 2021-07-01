//
//  StickerCollectionViewController.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 30.06.2021.
//

import UIKit

final class StickerCollectionViewController: UICollectionViewController {
    private var cellSize = CGSize.zero
    
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

// MARK: - UICollectionViewDataSource

extension StickerCollectionViewController {
    private static let reuseIdentifier = "StickerCell"
    
    override func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int { 100 }
    
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: Self.reuseIdentifier,
            for: indexPath) as! StickerImageCell
        
        // Configure the cell
        cell.backgroundColor = .systemFill
        
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
