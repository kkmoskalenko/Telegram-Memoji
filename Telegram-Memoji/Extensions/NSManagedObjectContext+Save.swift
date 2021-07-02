//
//  NSManagedObjectContext+Save.swift
//  Telegram-Memoji
//
//  Created by Konstantin Moskalenko on 02.07.2021.
//

import CoreData
import UIKit

extension NSManagedObjectContext {
    func saveIfNeeded() {
        guard hasChanges else { return }
        do { try save() } catch let error as NSError {
            print("Error: \(error), \(error.userInfo)")
        }
    }
}

extension UIViewController {
    static var managedObjectContext: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
}
