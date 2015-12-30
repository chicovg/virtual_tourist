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
    let kRegionKey = "Region"
    let kSegueToPhotoAlbum = "segueToPhotoAlbumView"

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
        
        if let camera = NSKeyedUnarchiver.unarchiveObjectWithFile("camera_file") as? MKMapCamera {
            mapView.camera = camera
        } else {
            // zoom to current location
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        print("viewDidAppear")
        if let camera = NSKeyedUnarchiver.unarchiveObjectWithFile("camera_file") as? MKMapCamera {
            mapView.camera = camera
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        print("viewWillDisappear")
        let camera = mapView.camera
        NSKeyedArchiver.archiveRootObject(camera, toFile: "camera_file")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                    Pin.Keys.longitude : coord.longitude,
                    Pin.Keys.hasPhotos : false
                ]
                _ = Pin(dictionary: dictionary as! [String : AnyObject], context: sharedContext)
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
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("regionDidChangeAnimated")
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("didSelectAnnotationView")
        if let annotation = view.annotation as? LocationAnnotation, pin = getPinForCoordinate(annotation.coordinate) {
            print("lat: \(pin.latitude.doubleValue) long: \(pin.longitude.doubleValue)")
            performSegueWithIdentifier(kSegueToPhotoAlbum, sender: pin)
        } else {
            // error?
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
    
    
}

