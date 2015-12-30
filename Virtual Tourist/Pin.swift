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
        static let hasPhotos = "hasPhoto"
    }
   
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var hasPhotos: Bool
    @NSManaged var photos: [Photo]

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName(Pin.ENTITY_NAME, inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.latitude] as! NSNumber
        longitude = dictionary[Keys.longitude] as! NSNumber
        hasPhotos = dictionary[Keys.hasPhotos] as! Bool
    }
}
