//
//  PhotoAlbumService.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/31/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import Foundation
import CoreData

let kPhotosPerPage: Int = 25
let kFailedToFetchPhotosNotification = "PhotosDeleted"

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
    func fetchPhotos(forLocation pin: Pin, photosPerPage: Int, callback: () -> Void) {
        let request = FlickrSearchRequest(latitude: pin.latitude.doubleValue, longitude: pin.longitude.doubleValue,
            page: pin.flickrPage, perPage: photosPerPage)
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
                callback()
                self.saveContext()
            } else {
                NSNotificationCenter.defaultCenter().postNotificationName(kFailedToFetchPhotosNotification, object: nil)
            }
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
