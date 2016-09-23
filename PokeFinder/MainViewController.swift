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
        
        let annotationIndentifier = "Pokemon"
        var annotationView: MKAnnotationView?
        
        // if its a user, use the ash location
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        // otherwise:
        // reuse annotations if needed
        } else if let dequeueAnnotation = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIndentifier) {
            annotationView = dequeueAnnotation
            annotationView?.annotation = annotation
        // create a default annotation
        } else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIndentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        // customize annotation
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
            // add pokemon image
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
            
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            annotationView.rightCalloutAccessoryView = btn
        }
        
        // return and show on the map
        return annotationView
        
    }

    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
        // call geoFirebase and set a gps location
        geoFire.setLocation(location, forKey: "\(pokeId)")
    }
    
    
    func showSightingsOnMap(location: CLLocation) {
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        // every time new pokemon is entered its called and add pokemon to the map
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            // when the app is called the first time, it cycles to show every single pokemon on the map(in its GPS location) and adds it as an annotation
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                self.mapView.addAnnotation(anno)
            }
        })
    }
    
    // update view when region changes(eg. user swipe)
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        showSightingsOnMap(location: loc)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // show the way to the pokemon in apple maps
        if let anno = view.annotation as? PokeAnnotation {
            // configuring apple maps
            let place = MKPlacemark(coordinate: anno.coordinate)
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking] as [String : Any]
            MKMapItem.openMaps(with: [destination], launchOptions: options)
        }
    }
    
    @IBAction func spotPokemon(_ sender: UIButton) {

        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        // select random pokemon
        let rand = arc4random_uniform(151) + 1
        // create a sighting
        createSighting(forLocation: loc, withPokemon: Int(rand))
    }
    
}

