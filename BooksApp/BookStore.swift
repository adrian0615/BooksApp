//
//  BookStore.swift
//  BooksApp
//
//  Created by Adrian McDaniel on 2/1/17.
//  Copyright © 2017 dssafsfsd. All rights reserved.
//

import UIKit
import CoreData

enum BookResult {
    case success([Book])
    case failure(Error)
}

//Dont have to save in this app!!!!!!!!!
class BookStore {
    let imageStore = ImageStore<String>()
    let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = CoreDataStack(modelName: "BooksApp")) {
        self.coreDataStack = coreDataStack
    }
    
    fileprivate let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
}

extension BookStore {
    
    func processBooksRequest(data: Data?, error: NSError?) -> BookResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return JohnWickAPI.booksFromJSONData(jsonData, inContext: self.coreDataStack.privateQueueContext)
    }
    
     func fetchMainQueueBooks(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [Book] {
        
        let fetchRequest = NSFetchRequest<Book>(entityName: "Book")
        fetchRequest.sortDescriptors = sortDescriptors
        
        let mainQueueContext = self.coreDataStack.mainQueueContext
        var mainQueueBook: [Book]?
        var fetchRequestError: Error?
        mainQueueContext.performAndWait({
            do {
                mainQueueBook = try mainQueueContext.fetch(fetchRequest)
            }
            catch let error {
                fetchRequestError = error
            }
        })
        
        guard let post = mainQueueBook else {
            throw fetchRequestError!
        }
        
        return post
    }
    
    internal func fetchBooks(completion: @escaping (BookResult) -> Void) {
        
        let url = JohnWickAPI.globalStreamURL
        let request = URLRequest(url: url as URL)
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) -> Void in
            
            var result = self.processBooksRequest(data: data, error: error as NSError?)
            
            if case let .success(books) = result {
                let privateQueueContext = self.coreDataStack.privateQueueContext
                privateQueueContext.performAndWait({
                    try! privateQueueContext.obtainPermanentIDs(for: books)
                })
                let objectIDs = books.map{ $0.objectID }
                //may need predicate to prevent duplication
                
                do {
                    try self.coreDataStack.saveChanges()
                    
                    let mainQueuePosts = try self.fetchMainQueueBooks(predicate: nil, sortDescriptors: [])
                    result = .success(mainQueuePosts)
                }
                catch let error {
                    result = .failure(error)
                }
            }
            completion(result)
        })
        task.resume()
    }
}

extension BookStore {
    func processImageRequest(data: Data?, error optionalError: NSError?) -> ImageResult {
        
        guard let imageData = data,
            let image = UIImage(data: imageData) else {
                if let error = optionalError {
                    return .systemFailure(error)
                } else {
                    return .systemFailure(ImageResult.Error.imageCreation)
                }
        }
        
        return .success(image)
    }
    
    func fetchImage(book: Book, completion: @escaping (ImageResult) -> Void) {
        
        let imageKey = book.imageKey!
        if let image = imageStore.imageForKey(imageKey) {
            completion(.success(image))
            return
        }
        
        let imageURL = URL(string: book.imageURLString)!
        let request = URLRequest(url: imageURL)
        
        let task = session.dataTask(with: request, completionHandler: {
            (data, response, error) -> Void in
            
            let result = self.processImageRequest(data: data, error: error as NSError?)
            
            if case let .success(image) = result {
                book.image = image
                self.imageStore.setImage(image, forKey: imageKey)
            }
            
            completion(result)
        }) 
        task.resume()
    }
}
