//
//  PhotoAlbumViewController.swift
//  VT
//
//  Created by Pablo Albuja on 7/12/20.
//  Copyright © 2020 Ingenuity Applications. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    var appDel: AppDelegate!
    
    var dataController:DataController!
    
    var pin: Pin!
    
    var photoPages: Int = 0
    
    let cache = NSCache<NSString, AnyObject>()
    
    let placeholderImage = UIImage(named: "placeholder")
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var errorMessage: UILabel!
    
    @IBOutlet weak var newCollectionBtn: UIBarButtonItem!
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!

    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        }catch{
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func deleteAllRecords(){
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo");
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        
        // Create Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try dataController.viewContext.execute(batchDeleteRequest)
            //try dataController.viewContext.save()
        } catch {
            fatalError("The batch delete request could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func deletePhoto(at indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDel = (UIApplication.shared.delegate as! AppDelegate)
        
        dataController = appDel.dataController
        
        setUpFetchedResultsController()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        if let photoCount = fetchedResultsController.fetchedObjects?.count{
            if photoCount == 0 {
                retrieveLocationPhotos()
            }else{
                newCollectionBtn.isEnabled = true
            }
        }
        
        if let location = pin {
            mapView.addAnnotation(location)
            var region: MKCoordinateRegion = mapView.region
            region.center.latitude = location.latitude
            region.center.longitude = location.longitude
            region.span.latitudeDelta = 0.05
            region.span.longitudeDelta = 0.05
            mapView.setRegion(region, animated: true)
        }
    }
    
    func retrieveLocationPhotos(){
        if let location = pin {
            newCollectionBtn.isEnabled = false
            if let pages = cache.object(forKey: "photoPages") {
                photoPages = pages as! Int
            }
            let page = photoPages > 1 ? Int.random(in:2...photoPages) : 1
            print("Page for API request: \(page), Location: \(location.latitude), \(location.longitude)")
            FlickrClient.getLocationPhotos(lat: location.latitude, lon: location.longitude, page:page, completion: handleLocationPhotoResponse(photos:error:))
        }
    }
    
    func handleLocationPhotoResponse(photos: Photos?, error: Error?){
        
        guard photos != nil && photos?.photo != nil && !photos!.photo.isEmpty else {
            errorMessage.isHidden = false
            return
        }
        photoPages = photos?.pages ?? 0
        cache.setObject(photoPages as NSNumber, forKey: "photoPages")
        errorMessage.isHidden = true
        var counter: Int = 0
        for photo in photos!.photo {
            let placeholder = addPlaceholderPhoto()
            FlickrClient.getPhoto(photo: photo, completion: { data, error in
                counter += 1
                if counter == photos!.photo.count {
                    self.newCollectionBtn.isEnabled = true
                }
                guard let data = data, error == nil else { return }
                self.updateWithDownloadedPhoto(photo: placeholder, data: data)
            })
        }
        
        
        
    }
    
    func addPlaceholderPhoto() -> Photo{
        let photo = Photo(context: dataController.viewContext)
        photo.pin = pin
        try? dataController.viewContext.save()
        return photo
    }
    
    func updateWithDownloadedPhoto(photo: Photo, data: Data){
        let photo = photo
        photo.content = data
        try? dataController.viewContext.save()
    }

    @IBAction func newCollectionPressed(_ sender: Any) {
        deleteAllRecords()
        setUpFetchedResultsController()
        retrieveLocationPhotos()
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionView.insertItems(at: [newIndexPath!])
            break
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        case .update:
            collectionView.reloadItems(at: [indexPath!])
        case .move:
            collectionView.moveItem(at: indexPath!, to: newIndexPath!)
        }
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! CollectionViewCell
        
        var image = placeholderImage
        if let photoContent = photo.content{
            image = UIImage(data: photoContent)
        }
        
        cell.photoImageView.image = image
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        deletePhoto(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (self.collectionView.frame.size.width - 20)/3, height: self.collectionView.frame.size.height/3)
    }
}
