//
//  PhotoImageCache.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/30/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import Foundation
import UIKit

class ImageService {
    
    // MARK: sharedInstance
    class func sharedInstance() -> ImageService {
        struct Static {
            static let instance = ImageService()
        }
        
        return Static.instance
    }
    
    private var inMemoryCache = NSCache()
    
    /** Get image from local cache, if it is not cached, dowload from Flickr */
    func getImageForUrl(urlString: String, handler: (image: UIImage?) -> Void) {
        if let url = NSURL(string: urlString), fileName = url.lastPathComponent {
            // if image is cached locally, get it, else fetch from flickr
            if let image = imageWithFilename(fileName) {
                handler(image: image)
            } else {
                FlickrClient.sharedInstance().getImage(urlString, completionHandler: { (response) -> Void in
                    if response.success && response.data != nil {
                        let image = UIImage(data: response.data!)
                        handler(image: image)
                        self.storeImage(image, withFileName: fileName)
                    } else {
                        handler(image: nil)
                        self.storeImage(nil, withFileName: fileName)
                    }
                })
            }
        }
        handler(image: nil)
    }
    
    // TODO need remove function
    
    // MARK: Helpers
    private func imageWithFilename(fileName: String?) -> UIImage? {
        
        if let fileName = fileName {
            let path = fullPathForFile(fileName)
            if let image = inMemoryCache.objectForKey(path) as? UIImage {
                return image
            } else if let data = NSData(contentsOfFile: path) {
                return UIImage(data: data)
            }
        }
        
        return nil
    }
    
    private func storeImage(image: UIImage?, withFileName fileName: String) {
        let path = fullPathForFile(fileName)
        
        if let image = image {
            inMemoryCache.setObject(image, forKey: path)
            let data = UIImagePNGRepresentation(image)!
            data.writeToFile(path, atomically: true)
        } else {
            inMemoryCache.removeObjectForKey(path)
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch _ {}
        }
    }
    
    private func fullPathForFile(filename: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(filename)
        
        return fullURL.path!
    }
}
