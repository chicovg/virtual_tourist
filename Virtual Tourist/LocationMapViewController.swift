//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/19/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationMapViewController : UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    let kCenterCoordinateKey = "CenterCoordinate"
    let kRegionSaved = "RegionSaved"
    let kCenterLatKey = "CenterLatKey"
    let kCenterLonKey = "CenterLonKey"
    let kSpanLatKey = "SpanLatKey"
    let kSpanLonKey = "SpanLonKey"
    let kSegueToPhotoAlbum = "segueToPhotoAlbumView"
    let kCameraFileName = "map_camera_file"

    @IBOutlet weak var mapView: MKMapView!
    var currentPin : LocationAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        fetchPins()
        setAnnotations()
        
        mapView.delegate = self
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        let userDefaults = NSUserDefaults.standardUserDefaults()

        if userDefaults.boolForKey(kRegionSaved) {
            let coordinate = CLLocationCoordinate2D(latitude: userDefaults.doubleForKey(kCenterLatKey), longitude: userDefaults.doubleForKey(kCenterLonKey))
            let span = MKCoordinateSpanMake(userDefaults.doubleForKey(kSpanLatKey), userDefaults.doubleForKey(kSpanLonKey))
            let region = MKCoordinateRegionMake(coordinate, span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        let region = mapView.region
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        userDefaults.setBool(true, forKey: kRegionSaved)
        userDefaults.setDouble(region.center.latitude, forKey: kCenterLatKey)
        userDefaults.setDouble(region.center.longitude, forKey: kCenterLonKey)
        userDefaults.setDouble(region.span.latitudeDelta, forKey: kSpanLatKey)
        userDefaults.setDouble(region.span.longitudeDelta, forKey: kSpanLonKey)
        super.viewWillDisappear(animated)
    }
    
    // MARK: navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier != nil && segue.identifier == kSegueToPhotoAlbum {
            if let pin = sender as? Pin, photoAlbumVC = segue.destinationViewController as? PhotoAlbumViewController {
                print("lat: \(pin.latitude.doubleValue) long: \(pin.longitude.doubleValue)")
                photoAlbumVC.pin = pin
            }
        }
    }
    
    // MARK: CoreData context
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext
    }
    
    // MARK: - Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: Pin.ENTITY_NAME)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Pin.Keys.latitude, ascending: true)]
        
        // Create the Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Return the fetched results controller. It will be the value of the lazy variable
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    } ()
    
    // MARK: NSFetchedResultsControllerDelegate
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        fetchPins()
        setAnnotations()
    }
    
    // MARK: UIGestureRecognizer
    func handleLongPress(recognizer: UIGestureRecognizer){
        let point = recognizer.locationInView(mapView)
        let coord = mapView.convertPoint(point, toCoordinateFromView: mapView)
        switch recognizer.state {
            case .Began :
                print("long press began")
                currentPin = LocationAnnotation(coordinate: coord)
                mapView.addAnnotation(currentPin!)
            
            case .Changed :
                print("long press changed")
                mapView.removeAnnotation(currentPin!)
                currentPin = LocationAnnotation(coordinate: coord)
                mapView.addAnnotation(currentPin!)
            
            case .Ended :
                print("long press ended")
                let dictionary = [
                    Pin.Keys.latitude : coord.latitude,
                    Pin.Keys.longitude : coord.longitude
                ]
                let pin = Pin(dictionary: dictionary, context: sharedContext)
                self.fetchPhotos(pin)
                CoreDataManager.sharedInstance().saveContext()
                currentPin = nil
            
            default : print("default")
        }
    }
    
    // MARK: MKMapViewDelegate    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        switch (newState) {
            case .Starting:
                view.dragState = .Dragging
            case .Ending, .Canceling:
                view.dragState = .None
            default: break
        }
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("didSelectAnnotationView")
        if let annotation = view.annotation as? LocationAnnotation, pin = getPinForCoordinate(annotation.coordinate) {
            print("lat: \(pin.latitude.doubleValue) long: \(pin.longitude.doubleValue)")
            performSegueWithIdentifier(kSegueToPhotoAlbum, sender: pin)
        }
    }
    
    // MARK: Helpers
    private func fetchPins() {
        // Execute the Fetch Request
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            print("Error in fetchPins(): \(error)")
        }
    }
    
    private func setAnnotations() {
        for pin in fetchedResultsController.fetchedObjects as! [Pin] {
            mapView.addAnnotation(LocationAnnotation(coordinate: CLLocationCoordinate2D(latitude: pin.latitude.doubleValue, longitude: pin.longitude.doubleValue)))
        }
    }
    
    private func getPinForCoordinate(coordinate: CLLocationCoordinate2D) -> Pin? {
        return (fetchedResultsController.fetchedObjects as! [Pin]).filter { (pin) -> Bool in
            return pin.latitude == (coordinate.latitude as NSNumber) &&
                pin.longitude == (coordinate.longitude as NSNumber)
        }.first
    }
    
    private func fetchPhotos(pin: Pin) {
        print("page: \(pin.flickrPage) pages: \(pin.flickrPages)")
        PhotoAlbumService.sharedInstance().fetchPhotos(forLocation: pin, photosPerPage: kPhotosPerPage) { (photoCount) -> Void in
            print("fetched \(photoCount) photos")
        }
    }
    
    
}

