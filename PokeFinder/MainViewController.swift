//
//  MainViewController.swift
//  PokeFinder
//
//  Created by Matthias Hofmann on 23.09.16.
//  Copyright © 2016 MatthiasHofmann. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class MainViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var mapHasCenteredOnce = false
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // mapview delegates
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        // firebase database reference
        geoFireRef = FIRDatabase.database().reference()
        // init geofire
        geoFire = GeoFire(firebaseRef: geoFireRef)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    // check for location Authorization
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // call when the user replys to auth request
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
    // center/zoom map on current location
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // updates mapview
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // center map on fist load
        if let loc = userLocation.location {
            if !mapHasCenteredOnce {
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
    }
    
    // create custom annotation(for user position)
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        var annotationView: MKAnnotationView?
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        }
        
        return annotationView
        
    }

    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
        // call geoFirebase and set a gps location
        geoFire.setLocation(location, forKey: "\(pokeId)")
    }
    
    
    func showSightingsOnMap(location: CLLocation) {
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                self.mapView.addAnnotation(anno)
            }
        })
    }
    
    
    @IBAction func spotPokemon(_ sender: UIButton) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        // select random pokemon
        let rand = arc4random_uniform(151) + 1
        // create a sighting
        createSighting(forLocation: loc, withPokemon: Int(rand))
    }
    
}

