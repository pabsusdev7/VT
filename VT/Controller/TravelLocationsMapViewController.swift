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
    
    
    var dataController:DataController!
       
    var fetchedResultsController:NSFetchedResultsController<Pin>!

    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        //let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        //fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
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
        
        setUpFetchedResultsController()
        
        // Generate long-press UIGestureRecognizer.
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        longPress.addTarget(self, action: #selector(recognizeLongPress(_:)))
        
        // Added UIGestureRecognizer to MapView.
        mapView.addGestureRecognizer(longPress)
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
        
        // Generate pins.
        let myPin: MKPointAnnotation = MKPointAnnotation()
        
        // Set the coordinates.
        myPin.coordinate = myCoordinate
        
        addPin(annotation: myPin)
        
        // Set the title.
        //myPin.title = "title"
        
        // Set subtitle.
        //myPin.subtitle = "subtitle"
        
        // Added pins to MapView.
        //mapView.addAnnotation(myPin)
    }
    
    func addPin(annotation: MKPointAnnotation){
        let pin = Pin(context: dataController.viewContext)
        pin.annotation = annotation
        try? dataController.viewContext.save()
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
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == view.rightCalloutAccessoryView {
            
            if let toOpen = URL(string: view.annotation?.subtitle! ?? "") {
                //app.openURL(URL(string: toOpen)!)
                UIApplication.shared.open(toOpen)
            }
        }
    }
    
}

