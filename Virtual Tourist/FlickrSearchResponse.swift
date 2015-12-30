//
//  FlickrSearchResponse.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/29/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import Foundation

struct FlickrSearchResponse {
    let response: FlickrResponse
    let page: Int
    let perPage: Int
    let pages: Int
    let photos: [[String: AnyObject]]
    
    init(response: FlickrResponse, page: Int, perPage: Int, pages: Int, photos: [[String: AnyObject]]){
        self.response = response
        self.page = page
        self.perPage = perPage
        self.pages = pages
        self.photos = photos
    }
    
    init(response: FlickrResponse, page: Int, perPage: Int){
        self.init(response: response, page: page, perPage: perPage, pages: 0, photos: [])
    }
    
    init(json: [String: AnyObject], page: Int, perPage: Int){
        if let stat = json["stat"] as? String {
            if stat == "ok" {
                if let photoDict = json["photos"] as? NSDictionary, pg = photoDict["page"] as? Int, ppg = photoDict["perpage"] as? Int, pgs = photoDict["pages"] as? Int, photos = photoDict["photo"] as? [[String: AnyObject]] {
                    self.init(response: FlickrResponse(responseType: .Success), page: pg, perPage: ppg, pages: pgs, photos: photos)
                    return
                }
            }
        }
        self.init(response: FlickrResponse(responseType: .InvalidResponse, errorDescription: "Unable to parse Flickr Response"), page: page, perPage: perPage)
    }
    
    var success: Bool {
        return response.success
    }
}


