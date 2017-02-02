//
//  Book+CoreDataClass.swift
//  BooksApp
//
//  Created by Adrian McDaniel on 2/1/17.
//  Copyright © 2017 dssafsfsd. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Book)
public class Book: NSManagedObject {
    
    var image: UIImage?

    
    static var entityName: String {
        return "Book"
    }
}
