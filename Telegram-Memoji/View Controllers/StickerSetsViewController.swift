//
//  StickerSetsViewController.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 28.06.2021.
//

import UIKit
import CoreData

final class StickerSetsViewController: UITableViewController {
    private lazy var fetchedResultsController:
        NSFetchedResultsController<StickerSet> = {
            let fetchRequest: NSFetchRequest = StickerSet.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(
                keyPath: \StickerSet.editDate, ascending: false
            )]
            
            let fetchedResultsController = NSFetchedResultsController(
                fetchRequest: fetchRequest,
                managedObjectContext: Self.managedObjectContext,
                sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
            
            return fetchedResultsController
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        try? fetchedResultsController.performFetch()
    }
}

// MARK: - UITableViewDataSource

extension StickerSetsViewController {
    private static let reuseIdentifier = "StickerSetListCell"
    
    private func configureCell(
        _ cell: UITableViewCell, at indexPath: IndexPath
    ) {
        let stickerSet = fetchedResultsController.object(at: indexPath)
        guard let stickers = stickerSet.stickers else { return }
        
        cell.textLabel?.text = "\(stickers.count) sticker"
        if stickers.count != 1 { cell.textLabel?.text?.append("s") }
        
        if let sticker = stickers.firstObject as? Sticker,
           let imageData = sticker.imageData,
           let image = UIImage(data: imageData)
        { cell.imageView?.image = image }
    }
    
    override func tableView(
        _ tableView: UITableView, numberOfRowsInSection section: Int
    ) -> Int { fetchedResultsController.fetchedObjects?.count ?? 0 }
    
    override func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.reuseIdentifier, for: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }
    
    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            let stickerSet = fetchedResultsController.object(at: indexPath)
            let context = fetchedResultsController.managedObjectContext
            
            context.delete(stickerSet)
            context.saveIfNeeded()
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension StickerSetsViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) { tableView.beginUpdates() }
    
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) { tableView.endUpdates() }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any, at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?
    ) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .automatic)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .automatic)
            case .move:
                tableView.deleteRows(at: [indexPath!], with: .automatic)
                tableView.insertRows(at: [newIndexPath!], with: .automatic)
            case .update:
                if let cell = tableView.cellForRow(at: indexPath!) {
                    configureCell(cell, at: indexPath!)
                }
            @unknown default: break
        }
    }
}

// MARK: - Performing a Segue

extension StickerSetsViewController {
    private static let segueIdentifier = "ShowStickerSetDetailSegue"
    
    @IBAction func addBarButtonAction(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: Self.segueIdentifier, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == Self.segueIdentifier,
              let destination = segue.destination as?
                StickerCollectionViewController
        else { return }
        
        if let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell)
        {
            let stickerSet = fetchedResultsController.object(at: indexPath)
            destination.stickerSet = stickerSet
        }
    }
}
