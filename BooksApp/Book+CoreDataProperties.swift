//
//  Book+CoreDataProperties.swift
//  BooksApp
//
//  Created by Adrian McDaniel on 2/1/17.
//  Copyright © 2017 dssafsfsd. All rights reserved.
//

import Foundation
import CoreData


extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book");
    }

    @NSManaged public var imageURLString: String
    @NSManaged public var imageKey: String?
    @NSManaged public var title: String
    @NSManaged public var author: String?

}
