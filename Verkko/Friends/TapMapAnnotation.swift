//
//  MKCustomAnnotation.swift
//  Verkko
//
//  Created by Mihir Rao on 6/22/23.
//

import UIKit
import MapKit

class TapMapAnnotation: NSObject, MKAnnotation {
    let id: Int!
    let coordinate: CLLocationCoordinate2D
    let address: String?

    init(id: Int, coord: CLLocationCoordinate2D, address: String? = "") {
        self.id = id
        self.coordinate = coord
        self.address = address
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
