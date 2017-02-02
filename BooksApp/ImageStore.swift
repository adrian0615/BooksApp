//
//  ImageStore.swift
//  BooksApp
//
//  Created by Adrian McDaniel on 2/1/17.
//  Copyright © 2017 dssafsfsd. All rights reserved.
//

import Foundation


import UIKit

enum ImageResult {
    case success(UIImage)
    case httpFailure(URLResponse)
    case systemFailure(Swift.Error)
    
    enum Error : Swift.Error {
        case imageCreation
        case noURL
    }
}


internal protocol ImageKeyExtractable {
    var imageKey: String { get }
}

extension ImageKeyExtractable {
    internal var imageKeyPathComponents: String {
        return imageKey
    }
}

extension String : ImageKeyExtractable {
    public var imageKey: String {
        return self
    }
}


internal protocol ImageURLExtractable {
    var networkURL: URL? { get }
}


extension FileManager {
    var documentsDirectory: URL {
        let documentsDirectories =
            FileManager.default.urls(for: .documentDirectory,
                                     in: .userDomainMask)
        
        return documentsDirectories.first!
    }
}

internal class ImageStore<Key: ImageKeyExtractable> {
    
    fileprivate let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    fileprivate let cache = NSCache<NSString, UIImage>()
    
    
    fileprivate func imageURLForKey(_ key: Key) -> URL {
        return FileManager.default.documentsDirectory.appendingPathComponent(key.imageKeyPathComponents)
    }
    
    internal func setImage(_ image: UIImage, forKey key: Key) {
        cache.setObject(image, forKey: key.imageKey as NSString)
        
        
        let imageURL = imageURLForKey(key)
        
        if let data = UIImageJPEGRepresentation(image, 1.0) {
            try? data.write(to: imageURL, options: [.atomic])
        }
    }
    
    internal func imageForKey(_ key: Key) -> UIImage? {
        if let existingImage = cache.object(forKey: key.imageKey as NSString) {
            return existingImage
        } else {
            let imageURL = imageURLForKey(key)
            
            guard let imageFromDisk = UIImage(contentsOfFile: imageURL.path) else {
                return nil
            }
            
            cache.setObject(imageFromDisk, forKey: key.imageKey as NSString)
            return imageFromDisk
        }
    }
    
    internal func removeImageForKey(_ key: Key) {
        cache.removeObject(forKey: key.imageKey as NSString)
        
        let imageURL = imageURLForKey(key)
        do {
            try FileManager.default.removeItem(at: imageURL)
        }
        catch {
            print("Error removing the image from disk: \(error)")
        }
    }
}

extension ImageStore where Key : ImageURLExtractable {
    internal func imageForKey(_ key: Key, completion: @escaping (ImageResult) -> Void) {
        if let existingImage = cache.object(forKey: key.imageKey as NSString) {
            completion(.success(existingImage))
            return
        }
        
        
        let imageURL = imageURLForKey(key)
        
        if let imageFromDisk = UIImage(contentsOfFile: imageURL.path) {
            cache.setObject(imageFromDisk, forKey: key.imageKey as NSString)
            completion(.success(imageFromDisk))
            return
        }
        
        
        fetchImage(key) { (result) in
            if case let .success(value) = result {
                self.setImage(value, forKey: key)
            }
            
            completion(result)
        }
    }
    
    
    func fetchImage(_ key: Key, completion: @escaping (ImageResult) -> Void) {
        guard let url = key.networkURL else {
            completion(.systemFailure(ImageResult.Error.noURL))
            return
        }
        
        session.dataTask(with: url) { (optionalData, optionalResponse, optionalError) in
            
            let result = self.processImageRequest(data: optionalData, response: optionalResponse, error: optionalError)
            completion(result)
        }
    }
    
    func processImageRequest(data: Data?, response: URLResponse?, error: Swift.Error?) -> ImageResult {
        
        if let imageData = data,
            let image = UIImage(data: imageData) {
            return .success(image)
        } else if let _response = response {
            return .httpFailure(_response)
        } else if let _error = error {
            return .systemFailure(_error)
        } else {
            return .systemFailure(ImageResult.Error.imageCreation)
        }
        
    }
}
