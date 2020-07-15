//
//  ViewController.swift
//  VT
//
//  Created by Pablo Albuja on 6/24/20.
//  Copyright © 2020 Ingenuity Applications. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var pin : Pin!
    
    var appDel: AppDelegate!
    
    var dataController:DataController!
       
    var fetchedResultsController:NSFetchedResultsController<Pin>!

    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
            mapView.addAnnotations(fetchedResultsController.fetchedObjects!)
        }catch{
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        appDel = (UIApplication.shared.delegate as! AppDelegate)
        
        dataController = appDel.dataController
        
        setUpFetchedResultsController()
        
        mapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if fetchedResultsController == nil {
            setUpFetchedResultsController()
        }
        // Generate long-press UIGestureRecognizer.
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(recognizeLongPress(_:)))
        
        // Added UIGestureRecognizer to MapView.
        mapView.addGestureRecognizer(longPress)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    @objc private func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        // Do not generate pins many times during long press.
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        
        // Get the coordinates of the point you pressed long.
        let location = sender.location(in: mapView)
        
        // Convert location to CLLocationCoordinate2D.
        let myCoordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        
        let cllLocation = CLLocation(latitude: myCoordinate.latitude, longitude: myCoordinate.longitude)
        
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(cllLocation) { (placemarks, error) in
            var locationDescription: String = ""
            
            // Most geocoding requests contain only one result.
            if let firstPlacemark = placemarks?.first {
                locationDescription = firstPlacemark.locality ?? ""
            }
            DispatchQueue.main.async {
                self.addPin(latitude: myCoordinate.latitude, longitude: myCoordinate.longitude, title: locationDescription)
            }
        }
    }
    
    func addPin(latitude: Double, longitude: Double, title: String){
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = latitude
        pin.longitude = longitude
        pin.title = title
        try? dataController.viewContext.save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhotoAlbum"{
            let photoAlbumVC = segue.destination as! PhotoAlbumViewController
            photoAlbumVC.pin = pin
        }
    }


}

extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            preconditionFailure("All changes observed in the map view controller should be for Pin instances")
        }
        
        switch type {
        case .insert:
            mapView.addAnnotation(pin)
            
        case .delete:
            mapView.removeAnnotation(pin)
            
        case .update:
            mapView.removeAnnotation(pin)
            mapView.addAnnotation(pin)
            
        case .move:
            fatalError("How did we move a Pin? We have a stable sort.")
        }
    }
    
}


extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {
           let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
           let latPredicate = NSPredicate(format: "latitude == %lf", annotation.coordinate.latitude)
           let lonPredicate = NSPredicate(format: "longitude == %lf", annotation.coordinate.longitude)
           let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [latPredicate, lonPredicate])
           fetchRequest.predicate = andPredicate
           let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
           fetchRequest.sortDescriptors = [sortDescriptor]
           fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
           do{
               try fetchedResultsController.performFetch()
               pin = fetchedResultsController.fetchedObjects?[0]
           }catch{
               fatalError("The fetch could not be performed: \(error.localizedDescription)")
           }
        }
        
        
        performSegue(withIdentifier: "showPhotoAlbum", sender: nil)
    }
    
}

