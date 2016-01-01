//
//  PhotoAlbumService.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/31/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import Foundation
import CoreData
import UIKit

let kPhotosPerPage: Int = 27
let kFailedToFetchPhotosNotification = "PhotoFetchFailed"

class PhotoAlbumService {
    
    // MARK: sharedInstance
    class func sharedInstance() -> PhotoAlbumService {
        struct Static {
            static let instance = PhotoAlbumService()
        }
        
        return Static.instance
    }
    
    // MARK: CoreData Context
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext
    }
    
    /** Fetchs photo data for pin and saves it to coredata */
    func fetchPhotos(forLocation pin: Pin, photosPerPage: Int, callback: (photoCount: Int) -> Void) {
        let request = FlickrSearchRequest(latitude: pin.latitude.doubleValue, longitude: pin.longitude.doubleValue,
            page: pin.flickrPage, perPage: photosPerPage)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        FlickrClient.sharedInstance().searchPhotosByLocation(request, completionHandler: { (response) -> Void in
            if response.success {
                pin.flickrPage = response.page
                pin.flickrPages = response.pages
                for photoResult in response.photos {
                    if let url = photoResult["url_s"] as? String {
                        var dict = [
                            Photo.Keys.urlString : url,
                            Photo.Keys.title : "",
                        ]
                        
                        if let title = photoResult["title"] as? String {
                            dict[Photo.Keys.title] = title
                        }
                        
                        let photo = Photo(dictionary: dict, context: self.sharedContext)
                        photo.pin = pin
                    }
                }
                callback(photoCount: response.photos.count)
                self.saveContext()
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(kFailedToFetchPhotosNotification, object: nil)
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        })
    }
    
    /** saves shared core data context */
    private func saveContext(){
        CoreDataManager.sharedInstance().saveContext()
        do {
            try sharedContext.save()
        } catch {
            let saveError = error as NSError
            print("\(saveError)")
        }
    }
}
