//
//  FindSpotViewController.swift
//  ParKing
//
//  Created by Kavin Aravind on 4/28/18.
//  Copyright © 2018 Group 10. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import FirebaseDatabase

class FindSpotViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    // Instance variable holding the object reference of the MKMapView object created in the Storyboard
    @IBOutlet var mapView: MKMapView!
    
    var ref: DatabaseReference!
    
    var latitudeToPass: Double?
    var longitudeToPass: Double?
    
    // The amount of north-to-south distance (measured in meters) to use for the span.
    let latitudinalSpanInMeters: Double = 1609.344    // = 1 mile
    
    // The amount of east-to-west distance (measured in meters) to use for the span.
    let longitudinalSpanInMeters: Double = 1609.344   // = 1 mile
    
    // Instantiate a CLLocationManager object
    var locationManager = CLLocationManager()
    
    var userAuthorizedLocationMonitoring = false
    
    var coordinateToPass = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //-----------------------------
        // Dress up the map view object
        //-----------------------------
        
        mapView.mapType = MKMapType.standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = false
        
        /*
         IMPORTANT NOTE: Current GPS location cannot be determined under the iOS Simulator
         on your laptop or desktop computer because those computers do NOT have a GPS antenna.
         Therefore, do NOT expect the code herein to work under the iOS Simulator!
         
         You must deploy your location-aware app to an iOS device to be able to test it properly.
         
         To develop a location-aware app:
         
         (1) Link to CoreLocation.framework in your Xcode project
         (2) Include "import CoreLocation" to use its classes.
         (3) Study documentation on CLLocation, CLLocationManager, and CLLocationManagerDelegate
         */
        
        /*
         The user can turn off location services on an iOS device in Settings.
         First, you must check to see of it is turned off or not.
         */
        
        if !CLLocationManager.locationServicesEnabled() {
            showAlertMessage(messageHeader: "Location Services Disabled!",
                             messageBody: "Turn Location Services On in your device settings to be able to use location services!")
            return
        }
        
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
            userAuthorizedLocationMonitoring = false
        } else {
            userAuthorizedLocationMonitoring = true
        }
        
        if !userAuthorizedLocationMonitoring {
            
            // User does not authorize location monitoring
            showAlertMessage(messageHeader: "Authorization Denied!",
                             messageBody: "Unable to determine current location!")
            return
        }
        
        // Set the current view controller to be the delegate of the location manager object
        locationManager.delegate = self
        
        // Set the location manager's distance filter to kCLDistanceFilterNone implying that
        // a location update will be sent regardless of movement of the device
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        // Set the location manager's desired accuracy to be the best
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Start the generation of updates that report the user’s current location.
        // Implement the CLLocationManager Delegate Methods below to receive and process the location info.
        
        locationManager.startUpdatingLocation()
        
        addPointsToMap()
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKUserLocation) {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: String(annotation.hash))
            
            let rightButton = UIButton(type: .contactAdd)
            rightButton.tag = annotation.hash
            
            pinView.animatesDrop = true
            pinView.canShowCallout = true
            pinView.rightCalloutAccessoryView = rightButton
            
            return pinView
        }
        else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            coordinateToPass = "\(view.annotation!.coordinate.latitude)" + "," + "\(view.annotation!.coordinate.longitude)"
            performSegue(withIdentifier: "GetDirections", sender: self)
        }
    }
    
    /*
     -------------------------
     MARK: - Prepare for Segue
     -------------------------
     
     This method is called by the system whenever you invoke the method performSegueWithIdentifier:sender:
     You never call this method. It is invoked by the system.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if segue.identifier == "GetDirections" {
            // Obtain the object reference of the destination (downstream) view controller
            let directionsViewController: DirectionsViewController = segue.destination as! DirectionsViewController
            
            directionsViewController.selectedLocationName = coordinateToPass
        }
    }
    
    func addPointsToMap() {
        ref = Database.database().reference()
        ref.child(currentCity.city).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let spots: [Any] = snapshot.value as! [Any]
            
            for spot in spots {
                
                let obj = spot as! Dictionary<String, Any>
                
                let annotation = MKPointAnnotation()
    
                let centerLocation = CLLocationCoordinate2D(latitude: obj["latitude"] as! Double, longitude: obj["longitude"] as! Double)
                
                // Dress up the newly created MKPointAnnotation() object
                annotation.coordinate = centerLocation
                annotation.title = (obj["availability"] as! Bool ? "Available!" : "Unavailable" )
                annotation.subtitle = ""
                let annotation_view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
                
                // Add the created and dressed up MKPointAnnotation() object to the map view
                self.mapView.addAnnotation(annotation_view.annotation!)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    /*
     ------------------------------------------
     MARK: - CLLocationManager Delegate Methods
     ------------------------------------------
     */
    // Tells the delegate that a new location data is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        /*
         The objects in the given locations array are ordered with respect to their occurrence times.
         Therefore, the most recent location update is at the end of the array; hence, we access the last object.
         */
        let lastObjectAtIndex = locations.count - 1
        let currentLocation: CLLocation = locations[lastObjectAtIndex] as CLLocation
        
        // Obtain current location's latitude in degrees
        latitudeToPass = currentLocation.coordinate.latitude
        
        // Obtain current location's longitude in degrees
        longitudeToPass = currentLocation.coordinate.longitude
        
        // Stops the generation of location updates since we do not need it anymore
        manager.stopUpdatingLocation()
        
        // To make sure that it really stops updating the location, set its delegate to nil
        locationManager.delegate = nil
        
        let centerLocation = CLLocationCoordinate2D(latitude: latitudeToPass!, longitude: longitudeToPass!)
        
        // Define map's visible region
        let centerRegion: MKCoordinateRegion? = MKCoordinateRegionMakeWithDistance(centerLocation, latitudinalSpanInMeters, longitudinalSpanInMeters)
        
        // Set the mapView to show the defined visible region
        mapView.setRegion(centerRegion!, animated: true)
        
        //*************************************
        // Prepare and Set VT Campus Annotation
        //*************************************
        
        // Instantiate an object from the MKPointAnnotation() class and place its obj ref into local variable annotation
        let annotation = MKPointAnnotation()
        
        // Dress up the newly created MKPointAnnotation() object
        annotation.coordinate = centerLocation
        annotation.title = "You are Here"
        annotation.subtitle = ""
        
        // Add the created and dressed up MKPointAnnotation() object to the map view
        mapView.addAnnotation(annotation)
        
    }
    
    /*
     ------------------------
     MARK: - Location Manager
     ------------------------
     */
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        // Stops the generation of location updates since error occurred
        manager.stopUpdatingLocation()
        
        // To make sure that it really stops updating the location, set its delegate to nil
        locationManager.delegate = nil
        
        showAlertMessage(messageHeader: "Unable to Locate You!",
                         messageBody: "An error occurred while trying to determine your location: \(error.localizedDescription)")
        return
    }
    
    /*
     -----------------------------
     MARK: - Display Alert Message
     -----------------------------
     */
    func showAlertMessage(messageHeader header: String, messageBody body: String) {
        
        /*
         Create a UIAlertController object; dress it up with title, message, and preferred style;
         and store its object reference into local constant alertController
         */
        let alertController = UIAlertController(title: header, message: body, preferredStyle: UIAlertControllerStyle.alert)
        
        // Create a UIAlertAction object and add it to the alert controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
    
    /*
     --------------------
     MARK: - Set Map Type
     --------------------
     */
    // This method is invoked when the user selects a map type to display
    @IBAction func setMapType(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = MKMapType.standard
        case 1:
            mapView.mapType = MKMapType.satellite
        case 2:
            mapView.mapType = MKMapType.hybrid
        default:
            return
        }
        
    }
    
    /*
     ------------------------------------------
     MARK: - MKMapViewDelegate Protocol Methods
     ------------------------------------------
     */
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        // Starting to load the map. Show the animated activity indicator in the status bar
        // to indicate to the user that the map view object is busy loading the map.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        // Finished loading the map. Hide the activity indicator in the status bar.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        
        // An error occurred during the map load. Hide the activity indicator in the status bar.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        /*
         Create a UIAlertController object; dress it up with title, message, and preferred style;
         and store its object reference into local constant alertController
         */
        let alertController = UIAlertController(title: "Unable to Load the Map!",
                                                message: "Error description: \(error.localizedDescription)",
            preferredStyle: UIAlertControllerStyle.alert)
        
        // Create a UIAlertAction object and add it to the alert controller
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
