//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/22/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {
    
    static let ENTITY_NAME: String = "Pin"
    
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let flickrPage = "flickrPage"
        static let flickrPages = "flickrPages"
    }
   
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var photos: [Photo]
    @NSManaged var flickrPage: Int
    @NSManaged var flickrPages: Int

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName(Pin.ENTITY_NAME, inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.latitude] as! NSNumber
        longitude = dictionary[Keys.longitude] as! NSNumber
        if let flickrPage = dictionary[Keys.flickrPage] as? Int {
            self.flickrPage = flickrPage
        } else {
            self.flickrPage = 1
        }
        if let flickrPages = dictionary[Keys.flickrPages] as? Int {
            self.flickrPages = flickrPages
        } else {
            self.flickrPages = 1
        }
    }
    
    var hasPhotos: Bool {
        return photos.count > 0
    }
    
    func incrementPage(){
        flickrPage = (flickrPage + 1 > flickrPages) ? 1 : flickrPage + 1
    }
}
