//
//  StickerSetsViewController.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 28.06.2021.
//

import UIKit

final class StickerSetsViewController: UITableViewController {
    
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
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        if sender is UIBarButtonItem {
            destination.stickerSet = StickerSet(context: context)
        } else if
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell)
        {
            // TODO: Handle the cell tap
            print("Tapped at \(indexPath)")
        }
    }
}
