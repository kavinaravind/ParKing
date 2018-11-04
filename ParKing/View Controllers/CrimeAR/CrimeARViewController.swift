//
//  CrimeARViewController.swift
//  ParKing
//
//  Created by Kavin Aravind on 4/28/18.
//  Copyright © 2018 Group 10. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import FirebaseDatabase
import CoreLocation

class CrimeARViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {
    
    // ARKit Scene
    @IBOutlet var sceneView: ARSCNView!
    
    // Firebase Database Reference
    var ref: DatabaseReference!
    
    // Create and initialize the Dict to store the crime data
    var dict_Theft_Data = [Int: NSArray]()
    
    // Instantiate a CLLocationManager object
    var locationManager = CLLocationManager()
    var userAuthorizedLocationMonitoring = false
    
    // The latitude and longitude of the current user
    var latitudeToPass: Double?
    var longitudeToPass: Double?
    
    // contains a dict of all the
    var parkingSpot: Dictionary<String, Any>?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Extracting Location Services
        if !CLLocationManager.locationServicesEnabled() {
            showAlertMessage(messageHeader: "Location Services Disabled!", messageBody: "Turn Location Services On in your device settings to be able to use location services!")
            return
        }
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
            userAuthorizedLocationMonitoring = false
        } else {
            userAuthorizedLocationMonitoring = true
        }
        
        //Get location before taking the photo
        if !userAuthorizedLocationMonitoring {
            // User does not authorize location monitoring
            showAlertMessage(messageHeader: "Authorization Denied!", messageBody: "Unable to determine current location!")
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
        
    }
    
    /*
     * Makes the API Calls:
     *
     * You would need the users current location to pull in relevant data. We will be using the SpotCrime api
     * (https://spotcrime.com) for pulling crimes in the area, and retrieving parking data from Firebase.
     */
    func crimeDataScraper() {

        // Spotcrime API URL
        let apiUrl = "http://api.spotcrime.com/crimes.json?lat=\(self.latitudeToPass! as Double)&lon=\(self.longitudeToPass! as Double)&radius=10&key=heythisisforpublicspotcrime.comuse-forcommercial-or-research-use-call-877.410.1607-or-email-pyrrhus-at-spotcrime.com"
        let url = URL(string: apiUrl)
        let jsonData: Data?
        do {
            jsonData = try Data(contentsOf: url!, options: NSData.ReadingOptions.mappedIfSafe)
        } catch {
            return
        }
        
        if let jsonDataFromApiUrl = jsonData {
            do {

                let jsonDataDictionary = try JSONSerialization.jsonObject(with: jsonDataFromApiUrl, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                // Typecast the returned NSDictionary as Dictionary<String, AnyObject>
                let dictionaryOfCountryJsonData = jsonDataDictionary! as! Dictionary<String, Any>
                
                let crimeData = dictionaryOfCountryJsonData["crimes"] as! NSArray as! [Any]
                
                var count = 0
                for (item) in crimeData  {
                    
                    // set data as a Dictionary
                    let data = item as! NSDictionary
    
                    // prevalent data
                    let type = data["type"] as! String
                    let date = data["date"] as! String
                    let address = data["address"] as! String
    
                    let crimeData = [type, date, address]
                    
                    // append all crimes within 10 miles to dict
                    dict_Theft_Data[count] = crimeData as NSArray
                    count+=1
                }
                
            } catch let error as NSError {
                print (error)
                return
            }
        }
        
        // retrieves the Firebase Database Reference
        ref = Database.database().reference()
        
        // iterates through the parking spots within the current city
        ref.child(currentCity.city).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let spots: [Any] = snapshot.value as! [Any] // gets the list of parking spots
            var coordinates = [CLLocationCoordinate2D]() // will store all of the coordinates from the parking spots
            let currentLocation = CLLocation(latitude: self.latitudeToPass! as Double, longitude: self.longitudeToPass! as Double) // sets the current location
            
            // iterates through the list of spots
            for spot in spots {
                
                // sets each spot as a dict
                let obj = spot as! Dictionary<String, Any>
                
                // creates a CLLocationCoordinate2D object from the latitude and longitude of the spot
                let centerLocation = CLLocationCoordinate2D(latitude: obj["latitude"] as! Double, longitude: obj["longitude"] as! Double)
                
                //appends these coordinates to an array
                coordinates.append(centerLocation)
                
            }
            
            // iterate through all of the coordinates, and order them based on how far they are from the
            // users current location
            let sortedCoordinates = coordinates.map({CLLocation(latitude: $0.latitude, longitude: $0.longitude)}).sorted(by: {
                $0.distance(from: currentLocation) < $1.distance(from: currentLocation)
            })
            
            // again iterate through the list of spots
            for spot in spots {
                
                // sets each spot as a dict
                let obj = spot as! Dictionary<String, Any>
                
                // if the closest spot to the users location is equal to the iterated spot, set that as the parking
                // spot to display
                if (obj["longitude"] as! Double == sortedCoordinates[0].coordinate.longitude && obj["latitude"] as! Double  == sortedCoordinates[0].coordinate.latitude) {
                    self.parkingSpot = obj
                }
                
            }
            
            // Sets the AR View for Parking Location Data
            self.spotLocation()
            
            // Sets the AR View for Crime Data
            self.crimeLocation()
            
        }) { (error) in
            print(error.localizedDescription)
        }
        

    }
    
    /*
     * ARView for Spot Information
     */
    func spotLocation() {
        
        // The root node for all Sprite Kit objects displayed in a view
        let skScene = SKScene(size: CGSize(width: 400, height: 300))
        skScene.backgroundColor = UIColor.clear

        // the panel that data will be written on top of
        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 400, height: 300), cornerRadius: 10)
        
        rectangle.fillColor = #colorLiteral(red: 0.807843148708344, green: 0.0274509806185961, blue: 0.333333343267441, alpha: 1.0)
        rectangle.strokeColor = #colorLiteral(red: 0.439215689897537, green: 0.0117647061124444, blue: 0.192156866192818, alpha: 1.0)
        rectangle.lineWidth = 5
        rectangle.alpha = 0.4
        
        let geocoder = CLGeocoder()
        
        // retrieve the current location
        let centerLocation = CLLocation(latitude: parkingSpot!["latitude"] as! Double, longitude: parkingSpot!["longitude"] as! Double)
        
        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(centerLocation, completionHandler: { (placemarks, error) in
            if error == nil {
                
                // reverse geocoding to retrieve the data to populate the address string
                let pm = placemarks! as [CLPlacemark]
                if pm.count > 0 {
                    let pm = placemarks![0]
                    var addressString : String = ""
                    if pm.subLocality != nil {
                        addressString = addressString + pm.subLocality! + ", "
                    }
                    if pm.thoroughfare != nil {
                        addressString = addressString + pm.thoroughfare! + ", "
                    }
                    if pm.locality != nil {
                        addressString = addressString + pm.locality! + ", "
                    }
                    if pm.country != nil {
                        addressString = addressString + pm.country! + ", "
                    }
                    if pm.postalCode != nil {
                        addressString = addressString + pm.postalCode! + " "
                    }
                    
                    // Once the address is found, output the spot information
                    // to String temp
                    var spot_information = "Spot Information\n"
                    spot_information += "Address: " + addressString + "\n"
                    spot_information += "Cost: " + (self.parkingSpot!["cost"] as! String) + "\n"
                    spot_information += "Available?: " + (self.parkingSpot!["availability"] as! Bool ? "Yes" : "No" ) + "\n"
                    spot_information += "Spot Type: " + (self.parkingSpot!["spotType"] as! String) + "\n"
                    
                    // A node that displays a text label
                    let labelNode = SKLabelNode()
                    labelNode.text = spot_information
                    labelNode.lineBreakMode = NSLineBreakMode.byWordWrapping
                    labelNode.numberOfLines = 10
                    labelNode.preferredMaxLayoutWidth = 300
                    labelNode.fontSize = 20
                    labelNode.fontName = "San Fransisco"
                    labelNode.position = CGPoint(x:150,y:120)
                    
                    skScene.addChild(rectangle) // add the display panel to the scene
                    skScene.addChild(labelNode) // add the text label to the scene
                    
                    // this makes the panel more visually appealing
                    let plane = SCNPlane(width: 20, height: 20)
                    
                    // A set of shading attributes that define the appearance of a geometry's
                    // surface when rendered
                    let material = SCNMaterial()
                    material.isDoubleSided = true
                    material.diffuse.contents = skScene
                    material.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
                    plane.materials = [material]
                    
                    // A structural element of a scene graph, representing a position and transform
                    // in a 3D coordinate space, to which you can attach geometry, lights, cameras, or other
                    // displayable content.
                    let node = SCNNode(geometry: plane)
                    node.position = SCNVector3(x: 25, y: 0, z: -50) // positioning
                    
                    // add the node to the main view
                    self.sceneView.scene.rootNode.addChildNode(node)
                }
            }
        })
    }
    
    /*
     * ARView for Crime Information
     */
    func crimeLocation() {
        
        // The root node for all Sprite Kit objects displayed in a view
        let skScene = SKScene(size: CGSize(width: 400, height: 300))
        skScene.backgroundColor = UIColor.clear
        
        // the panel that data will be written on top of
        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 400, height: 300), cornerRadius: 10)
        
        rectangle.fillColor = #colorLiteral(red: 0.807843148708344, green: 0.0274509806185961, blue: 0.333333343267441, alpha: 1.0)
        rectangle.strokeColor = #colorLiteral(red: 0.439215689897537, green: 0.0117647061124444, blue: 0.192156866192818, alpha: 1.0)
        rectangle.lineWidth = 5
        rectangle.alpha = 0.4
        
        // Get the most recent crime data within a 10 mile radius from the users current location
        var temp = "CRIMES WIthin 10 Mile Radius\n"
        temp += "1) " + (dict_Theft_Data[0]![0] as! String) + "\n" + (dict_Theft_Data[0]![1] as! String) + " - " +  (dict_Theft_Data[0]![2] as! String) + "\n"
        temp += "2) " + (dict_Theft_Data[1]![0] as! String) + "\n" + (dict_Theft_Data[1]![1] as! String) +  " - " +  (dict_Theft_Data[1]![2] as! String) + "\n"
        temp += "3) " + (dict_Theft_Data[2]![0] as! String) + "\n" + (dict_Theft_Data[2]![1] as! String) +  " - " +  (dict_Theft_Data[2]![2] as! String) + "\n"
        
        // A node that displays a text label
        let labelNode = SKLabelNode()
        labelNode.text = temp
        labelNode.lineBreakMode = NSLineBreakMode.byWordWrapping
        labelNode.numberOfLines = 10
        labelNode.preferredMaxLayoutWidth = 300
        labelNode.fontSize = 20
        labelNode.fontName = "San Fransisco"
        labelNode.position = CGPoint(x:150,y:20)
        
        skScene.addChild(rectangle) // add the display panel to the scene
        skScene.addChild(labelNode) // add the text label to the scene
        
        // this makes the panel more visually appealing
        let plane = SCNPlane(width: 20, height: 20)
        
        // A set of shading attributes that define the appearance of a geometry's
        // surface when rendered
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.diffuse.contents = skScene
        material.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        plane.materials = [material]
        
        // A structural element of a scene graph, representing a position and transform
        // in a 3D coordinate space, to which you can attach geometry, lights, cameras, or other
        // displayable content.
        let node = SCNNode(geometry: plane)
        node.position = SCNVector3(x: -25, y: 0, z: -50)
        
        // add the node to the main view
        sceneView.scene.rootNode.addChildNode(node)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Run the view's session
        self.sceneView.session.run(configuration)
        
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
        
        crimeDataScraper()

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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    /*
     // Override to create and configure nodes for anchors added to the view's session.
     func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }

}
