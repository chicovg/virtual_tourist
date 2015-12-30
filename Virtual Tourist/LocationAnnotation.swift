//
//  LocationAnnotation.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/19/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import Foundation
import MapKit

class LocationAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D){
        self.coordinate = coordinate
        super.init()
    }
    
}
