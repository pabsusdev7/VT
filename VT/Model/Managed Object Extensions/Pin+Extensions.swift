//
//  Pin+Extensions.swift
//  VT
//
//  Created by Pablo Albuja on 6/30/20.
//  Copyright © 2020 Ingenuity Applications. All rights reserved.
//

import Foundation
import MapKit

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        
        let latDegrees = CLLocationDegrees(latitude)
        let longDegrees = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
        
    }
    
}

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
