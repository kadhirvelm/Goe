//
//  GoeAdventureLocation.swift
//  Goe
//
//  Created by Kadhir M on 8/16/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import MapKit

class GoeAdventureLocation: NSObject, MKAnnotation {
    
    /** Title. */
    let title: String?
    /** Destination or rendezvous for this location. */
    let destination_rendezvous: String
    /** Coordinate for this location. */
    let coordinate: CLLocationCoordinate2D
    /** All errors this class can throw. */
    enum GoeAdventureLocationError: ErrorType {
        case InvalidDestinationRendezvous
    }
    /** Subtitle. */
    var subtitle: String? {
        return destination_rendezvous
    }
    
    init(title: String, destination_rendezvous: String, coordinate: CLLocationCoordinate2D) throws {
        self.title = title
        guard (destination_rendezvous == "Destination" || destination_rendezvous == "Rendezvous") else { throw GoeAdventureLocationError.InvalidDestinationRendezvous }
        self.destination_rendezvous = destination_rendezvous
        self.coordinate = coordinate
        super.init()
    }
    
}