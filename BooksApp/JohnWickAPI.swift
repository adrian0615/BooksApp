//
//  JohnWickAPI.swift
//  BooksApp
//
//  Created by Adrian McDaniel on 2/1/17.
//  Copyright © 2017 dssafsfsd. All rights reserved.
//

import Foundation
import CoreData

class JohnWickAPI {
    enum Error: Swift.Error {
        case invalidJSONData
    }
    
    internal static let globalStreamURL: URL = URL(string:"http://calm-mountain-87063.herokuapp.com/books.json")!
    
    
   
    
    class func booksFromJSONData(_ data: Data, inContext context: NSManagedObjectContext) -> BookResult {
        
        
        do {
            guard let jsonObject: [String: Any] = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let bookArray = jsonObject["data"] as? [[String: NSObject]] else {
                    
                    // The JSON structure doesn't match our expectations
                    return .failure(Error.invalidJSONData)
            }
            
            var returnedBooks = [Book]()
            for bookJSON in bookArray {
                if let book = bookFromJSONObject(bookJSON, inContext: context) {
                    returnedBooks.append(book)
                }
            }
            
            if returnedBooks.count == 0 && bookArray.count > 0 {
                
                return .failure(Error.invalidJSONData)
            }
            return .success(returnedBooks)
        }
        catch let error {
            return .failure(error)
        }
    }
    
    fileprivate class func bookFromJSONObject(_ json: [String : AnyObject],
                                              inContext context: NSManagedObjectContext) -> Book? {
        
        let bookAuthor = json["author"] as? String
        
        
        
        guard let bookTitle = json["title"] as? String,
            let imageURL = json["image_url"] as? String else {
                
                return nil
        }
        
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        
        
        let fetchedBooks: [Book] = {
            var books: [Book]!
            context.performAndWait() {
                books = try! context.fetch(fetchRequest) as! [Book]
            }
            
            
            return books
        }()
        
        if let firstBook = fetchedBooks.first {
            return firstBook
        }
        
        var book: Book!
        
        //performAndWait means do it now and I will wait for you to finish.  Inserting Book object into the context.
        context.performAndWait({ () -> Void in
            book = NSEntityDescription.insertNewObject(forEntityName: Book.entityName,
                                                       into: context) as! Book
            book.title = bookTitle
            book.author = bookAuthor
            book.imageURLString = imageURL
            
        })
        
        return book
    }
    
}
