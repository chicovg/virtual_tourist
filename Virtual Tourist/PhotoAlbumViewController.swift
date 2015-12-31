//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Victor Guthrie on 12/23/15.
//  Copyright © 2015 chicovg. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    let kPhotoCollectionViewCellId = "photoCollectionViewCell"
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var coordinate: CLLocationCoordinate2D?
    var pin: Pin!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up collection view
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        photoCollectionView!.registerClass(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: kPhotoCollectionViewCellId)
        
        let space: CGFloat = 3.0
        let dimension = (self.view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
        
        // place pin and get photos
        if !pin.hasPhotos {
            newCollectionButton.enabled = false
            searchPhotos()
        }
        placePin()
        fetchPhotos()
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController?.navigationBarHidden = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleFetchError", name: kFailedToFetchPhotosNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.navigationBarHidden = true
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Actions
    @IBAction func getNewPhotoCollection(sender: UIBarButtonItem) {
        // remove current photos and fetch a new page
        removePhotos()
        pin.incrementPage()
        searchPhotos()
    }
    
    // MARK: CoreData Context
    var sharedContext: NSManagedObjectContext {
        return CoreDataManager.sharedInstance().managedObjectContext
    }
    
    // MARK: Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: Photo.ENTITY_NAME)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Photo.Keys.title, ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin!);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        
    }()
    
    // MARK: NSFetchedResultsControllerDelegate
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("content changed")
        fetchPhotos()
        fetchPin()
        photoCollectionView.reloadData()
    }
    
    // MARK: UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections[section].numberOfObjects
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // get cell and set placeholder image
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kPhotoCollectionViewCellId, forIndexPath: indexPath) as! PhotoCollectionViewCell
        cell.photoImageView.image = UIImage(named: "Placeholder")
        
        // get photo entity and use url to fetch image asyncronously
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        ImageService.sharedInstance().getImage(byObjectURL: photo.objectID.URIRepresentation(), orBy: photo.urlString) { (image) -> Void in
            if let image = image {
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    cell.photoImageView.image = image
                })
            }
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        sharedContext.deleteObject(photo)
        saveContext()
        collectionView.reloadData()
    }
    
    // MARK: Handle photo fetching errors
    func handleFetchError(){
        let alert = UIAlertController(title: "Error", message: "Could not fetch photos for location!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: Helpers
    private func placePin(){
        if let pin = pin {
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude.doubleValue, longitude: pin.longitude.doubleValue)
            let annotation = LocationAnnotation(coordinate: coordinate)
            let span = MKCoordinateSpanMake(2.0, 2.0)
            let region = MKCoordinateRegionMake(coordinate, span)
            mapView.addAnnotation(annotation)
            mapView.setRegion(region, animated: true)
        }
    }
    
    /** fetches saved photos from Core Data */
    private func fetchPhotos() {
        // Execute the Fetch Request
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error in fetchPhotos(): \(error)")
        }
    }
    
    /** fetches pin from Core Data */
    private func fetchPin(){
        do {
            try pin = sharedContext.existingObjectWithID(pin.objectID) as! Pin
        } catch let error as NSError {
            print("Error in fetchPin(): \(error)")
        }
    }
    
    /** Searches Flickr for photos tagged with given latitude and longitude */
    private func searchPhotos() {
        print("page: \(pin.flickrPage) pages: \(pin.flickrPages)")
        PhotoAlbumService.sharedInstance().fetchPhotos(forLocation: pin, photosPerPage: kPhotosPerPage) { () -> Void in
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                self.newCollectionButton.enabled = true
            })
        }
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
    
    /** deletes all photos from the album */
    private func removePhotos(){
        if let photos = fetchedResultsController.fetchedObjects as? [Photo] {
            for photo in photos {
                sharedContext.deleteObject(photo)
            }
        }
    }
}
