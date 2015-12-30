//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/22/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {
    
    static let ENTITY_NAME: String = "Photo"
    
    struct Keys {
        static let title = "title"
        static let urlString = "urlString"
        static let pin = "pin"
    }

    @NSManaged var title: String
    @NSManaged var urlString: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName(Photo.ENTITY_NAME, inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        title = dictionary[Keys.title] as! String
        urlString = dictionary[Keys.urlString] as! String
        if let pin = dictionary[Keys.pin] as? Pin {
            self.pin = pin
        }
    }
}
