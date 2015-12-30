//
//  FlickrResponse.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/29/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import Foundation

enum FlickrResponseType: String {
    case Success
    case NoData
    case InvalidRequest
    case ServerError
    case InvalidResponse
}

struct FlickrResponse {
    let responseType: FlickrResponseType
    var data: NSData?
    var errorDescription: String?
    
    init(responseType: FlickrResponseType, errorDescription: String?, data: NSData?){
        self.responseType = responseType
        self.errorDescription = errorDescription
        self.data = data
    }
    
    init(responseType: FlickrResponseType){
        self.init(responseType: responseType, errorDescription: nil, data: nil)
    }
    
    init(responseType: FlickrResponseType, errorDescription: String){
        self.init(responseType: responseType, errorDescription: errorDescription, data: nil)
    }
    
    init(responseType: FlickrResponseType, data: NSData){
        self.init(responseType: responseType, errorDescription: nil, data: data)
    }
    
    var success : Bool {
        return responseType == .Success
    }
}
