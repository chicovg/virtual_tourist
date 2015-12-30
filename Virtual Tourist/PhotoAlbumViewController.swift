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
    let kPhotosPerPage: Int = 25
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var coordinate: CLLocationCoordinate2D?
    var pin: Pin!
    var page: Int = 1
    var pages: Int = 1

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
        placePin()
        if pin.hasPhotos {
            fetchPhotos()
        } else {
            newCollectionButton.enabled = false
            searchPhotos()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationController?.navigationBarHidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationController?.navigationBarHidden = true
    }
    
    // MARK: Actions
    @IBAction func getNewPhotoCollection(sender: UIBarButtonItem) {
        // remove current photos and fetch a new page
        removePhotos()
        page = (page + 1 > pages) ? 1 : page + 1
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
        fetchPhotos()
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
        ImageService.sharedInstance().getImageForUrl(photo.urlString) { (image) -> Void in
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
    
    // MARK: Helpers
    private func placePin(){
        if let pin = pin {
            print("lat: \(pin.latitude.doubleValue) long: \(pin.longitude.doubleValue)")
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
    
    /** Searches Flickr for photos tagged with given latitude and longitude */
    private func searchPhotos() {
        print("page: \(page) pages: \(pages)")
        let request = FlickrSearchRequest(latitude: pin.latitude.doubleValue, longitude: pin.longitude.doubleValue,
            page: page, perPage: kPhotosPerPage)
        FlickrClient.sharedInstance().searchPhotosByLocation(request, completionHandler: { (response) -> Void in
            if response.success {
                self.page = response.page
                self.pages = response.pages
                for photoResult in response.photos {
                    if let url = photoResult["url_s"] as? String {
                        var dict = [
                            Photo.Keys.urlString : url,
                            Photo.Keys.title : "",
                            Photo.Keys.pin : self.pin
                        ]
                        
                        if let title = photoResult["title"] as? String {
                            dict[Photo.Keys.title] = title
                        }
                        
                        _ = Photo(dictionary: dict, context: self.sharedContext)
                    }
                }
                self.pin.hasPhotos = true
                self.saveContext()
                self.newCollectionButton.enabled = true
            }
        })
    }
    
    /** saves shared core data context */
    private func saveContext(){
        do {
            try sharedContext.save()
        } catch {
            print("error saving context")
        }
    }
    
    private func removePhotos(){
        for photo in pin.photos {
            sharedContext.deleteObject(photo)
        }
    }
}
