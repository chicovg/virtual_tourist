//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/19/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import Foundation

class FlickrClient {
    
    let kTimeoutInterval = 10.0
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_PARAM = "method"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY_PARAM = "api_key"
    let API_KEY = "162144627ad2f1e729239fdceff0e099"
    let FORMAT_PARAM = "format"
    let FORMAT = "json"
    let LATITUDE_PARAM = "lat"
    let LONGITUDE_PARAM = "lon"
    let NO_JSON_CALLBACK_PARAM = "nojsoncallback"
    let NO_JSON_CALLBACK = "1"
    let EXTRAS_PARAM = "extras"
    let EXTRAS = "url_s"
    let PAGE_PARAM = "page"
    let PER_PAGE_PARAM = "per_page"
    
    // MARK: sharedInstance
    class func sharedInstance() -> FlickrClient {
        struct Static {
            static let instance = FlickrClient()
        }
        
        return Static.instance
    }

    /** Uses the Flickr API to find images by geo tag */
    func searchPhotosByLocation(searchRequest: FlickrSearchRequest, completionHandler: (searchResponse: FlickrSearchResponse) -> Void) {
        let params = [
            METHOD_PARAM : METHOD_NAME,
            API_KEY_PARAM : API_KEY,
            FORMAT_PARAM : FORMAT,
            NO_JSON_CALLBACK_PARAM : NO_JSON_CALLBACK,
            LATITUDE_PARAM : "\(searchRequest.latitude)",
            LONGITUDE_PARAM : "\(searchRequest.longitude)",
            EXTRAS_PARAM : EXTRAS,
            PAGE_PARAM : "\(searchRequest.page)",
            PER_PAGE_PARAM : "\(searchRequest.perPage)"
        ]
        let searchURL = BASE_URL + formatParameters(params)
        print(searchURL)
        if let url = NSURL(string: searchURL) {
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "GET"
            
            sendRequest(request, completionHandler: {
                response in
                
                if response.success {
                    /* 6 - Parse the data (i.e. convert the data to JSON and look for values!) */
                    let parsedResult: AnyObject!
                    do {
                        parsedResult = try NSJSONSerialization.JSONObjectWithData(response.data!, options: .AllowFragments)
                    } catch {
                        parsedResult = nil
                        print("Could not parse the data as JSON: '\(response.data)'")
                        let response = FlickrResponse(responseType: .InvalidResponse, errorDescription: "Could not parse the data as JSON: '\(response.data)'")
                        completionHandler(searchResponse: FlickrSearchResponse(response: response, page: searchRequest.page, perPage: searchRequest.perPage))
                        return
                    }
                    
                    let response = FlickrSearchResponse(json: parsedResult as! [String : AnyObject], page: 1, perPage: 10)
                    completionHandler(searchResponse: response)
                } else {
                    print("An invalid or empty response was returned")
                    completionHandler(searchResponse: FlickrSearchResponse(response: response, page: searchRequest.page, perPage: searchRequest.perPage))
                }
            })
        } else {
            print("Invalid url: \(searchURL)")
            let response = FlickrResponse(responseType: .InvalidRequest, errorDescription: "Invalid url: \(searchURL)")
            completionHandler(searchResponse: FlickrSearchResponse(response: response, page: searchRequest.page, perPage: searchRequest.perPage))
        }
    }
    
    /** Fetches a specific image by url */
    func getImage(urlString: String, completionHandler: (response: FlickrResponse) -> Void) {
        if let url = NSURL(string: urlString) {
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "GET"
            
            sendRequest(request, completionHandler: {
                response in
                completionHandler(response: response)
            })
        } else {
            print("Invalid url: \(urlString)")
            completionHandler(response: FlickrResponse(responseType: .InvalidRequest, errorDescription: "Invalid url: \(urlString)"))
        }
    }
    
    // MARK: Helpers
    private func formatParameters(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            if let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                /* Append it */
                urlVars.append("\(key)=\(escapedValue)")
            }
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    private func sendRequest(request: NSURLRequest, completionHandler: (FlickrResponse) -> Void) {
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: {
           (data, response, error) -> Void in
            completionHandler(self.extractResponse(data, response: response, error: error))
        })
        task.resume()
    }
    
    private func extractResponse(data: NSData?, response: NSURLResponse?, error: NSError?) -> FlickrResponse {
        guard (error == nil) else {
            print("The was an error searching Flickr: \(error)")
            return FlickrResponse(responseType: .InvalidRequest, errorDescription: "The was an error searching Flickr: \(error)")
        }
        
        guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
            if let response = response as? NSHTTPURLResponse {
                print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                return FlickrResponse(responseType: .InvalidRequest, errorDescription: "Your request returned an invalid response! Status code: \(response.statusCode)!")
            } else if let response = response {
                return FlickrResponse(responseType: .InvalidRequest, errorDescription: "Your request returned an invalid response! Status code: \(response)!")
            } else {
                return FlickrResponse(responseType: .InvalidRequest, errorDescription: "Your request returned an invalid response!")
            }
        }
        
        if let data = data {
            return FlickrResponse(responseType: .Success, data: data)
        } else {
            return FlickrResponse(responseType: .NoData)
        }
    }
    
    private func buildRequest(url: String, method: String, httpHeaders: [String: String]?, httpBody: String?) -> NSURLRequest? {
        let request = NSMutableURLRequest(URL: NSURL(string: url)!, cachePolicy: .ReloadIgnoringCacheData, timeoutInterval: kTimeoutInterval)
        request.HTTPMethod = method
        
        if let headers = httpHeaders {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = httpBody {
            request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        }
        return request
    }

    
}
