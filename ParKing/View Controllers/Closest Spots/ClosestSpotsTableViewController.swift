//
//  ClosestSpotsTableViewController.swift
//  ParKing
//
//  Created by CS3714 on 4/30/18.
//  Copyright © 2018 Group 10. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseDatabase
import FirebaseStorage

class ClosestSpotsTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    // Instance variable holding the object reference of the UITableView UI object created in the Storyboard
    @IBOutlet var closestSpotsTableView: UITableView!
    
    //Database reference
    var ref: DatabaseReference!
    
    // Instantiate a CLLocationManager object
    var locationManager = CLLocationManager()
    var userAuthorizedLocationMonitoring = false
    
    //Current Location
    var curLong: Double?
    var curLat: Double?
    
    //Coordinate of the spot to pass the directions
    var coordinateToPass = ""
    
    //Custom Table row height
    let tableViewRowHeight: CGFloat = 70.0
    
    // Alternate table view rows have a background color of MintCream or OldLace for clarity of display
    
    // Define MintCream color: #F5FFFA  245,255,250
    let MINT_CREAM = UIColor(red: 245.0/255.0, green: 255.0/255.0, blue: 250.0/255.0, alpha: 1.0)
    
    // Define OldLace color: #FDF5E6   253,245,230
    let OLD_LACE = UIColor(red: 253.0/255.0, green: 245.0/255.0, blue: 230.0/255.0, alpha: 1.0)
    
    //---------- Create and Initialize the Arrays -----------------------
    
    var citySpots = [Dictionary<String, Any>]()
    var citySpotPhotos = Dictionary<Int, UIImage>()
    var photoNumbers = [Int]()
    var spotOrder = [Dictionary<String, Any>]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Location Services checks
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

        // Preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false
    }

    //----------------------------------------
    // Return Number of Sections in Table View
    //----------------------------------------
    
    // We have only one section in the table view
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    //---------------------------------
    // Return Number of Rows in Section
    //---------------------------------
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return citySpots.count
    }
    
    //-------------------------------------
    // Prepare and Return a Table View Cell
    //-------------------------------------
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let rowNumber = (indexPath as NSIndexPath).row
        
        // Obtain the object reference of a reusable table view cell object instantiated under the identifier
        // ClosestSpot Cell, which was specified in the storyboard
        let cell: ClosestSpotTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ClosestSpot Cell") as! ClosestSpotTableViewCell
        
        // Obtain the spot
        let givenSpot = citySpots[rowNumber]
        
        let spotLat = givenSpot["latitude"]
        let spotLong = givenSpot["longitude"]
        
        let geocoder = CLGeocoder()
        
        let centerLocation = CLLocation(latitude: spotLat as! Double, longitude: spotLong as! Double)
        
        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(centerLocation, completionHandler: { (placemarks, error) in
            if error == nil {
                
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
                    cell.spotAddressLabel.text = addressString
                }
            }
        })
        cell.spotTypeLabel.text = givenSpot["spotType"] as? String
        let myCenterLocation = CLLocation(latitude: curLat!, longitude: curLong!)
        let distanceInMeters = centerLocation.distance(from: myCenterLocation)
        let distanceInMiles = distanceInMeters * 0.000621371
        cell.spotDistanceLabel.text = String(format: "%0.02F", distanceInMiles) + " Miles"
        
        if(citySpotPhotos[rowNumber] != nil) {
            cell.spotImageView.image = citySpotPhotos[rowNumber]
        } else {
            switch currentCity.city {
            case "Blacksburg, VA":
                cell.spotImageView.image = #imageLiteral(resourceName: "photo1")
            case "New York, NY":
                cell.spotImageView.image = #imageLiteral(resourceName: "photo2")
            case "Los Angeles, CA":
                cell.spotImageView.image = #imageLiteral(resourceName: "photo3")
            case "San Francisco, CA":
                cell.spotImageView.image = #imageLiteral(resourceName: "photo4")
            case "Washington, DC":
                cell.spotImageView.image = #imageLiteral(resourceName: "photo5")
            case "Seattle, WA":
                cell.spotImageView.image = #imageLiteral(resourceName: "photo6")
            case "Chicago, IL":
                cell.spotImageView.image = #imageLiteral(resourceName: "photo7")
            default:
                cell.spotImageView.image = #imageLiteral(resourceName: "photo1")
            }
            
        }
        return cell
    }
    
    //get the spot number in the city
    func getSpotNum(currentSpot: Dictionary<String, Any>) -> Int {
        var spotNum = 0
        for spot in spotOrder {
            if (currentSpot["longitude"] as! Double == spot["longitude"] as! Double && currentSpot["latitude"] as! Double  == spot["latitude"] as! Double) {
                return spotNum
            }
            spotNum+=1
        }
        return spotNum
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
        curLat = currentLocation.coordinate.latitude
        
        // Obtain current location's longitude in degrees
        curLong = currentLocation.coordinate.longitude
        
        // Stops the generation of location updates since we do not need it anymore
        manager.stopUpdatingLocation()
        
        // To make sure that it really stops updating the location, set its delegate to nil
        locationManager.delegate = nil
        
        ref = Database.database().reference()
        
        ref.child(currentCity.city).observeSingleEvent(of: .value, with: { (snapshot) in
            
            let spots: [Any] = snapshot.value as! [Any]
            var coordinates = [CLLocationCoordinate2D]()
            let currentLocation = CLLocation(latitude: self.curLat!, longitude: self.curLong!)
            for spot in spots {
                
                let obj = spot as! Dictionary<String, Any>
                
                let centerLocation = CLLocationCoordinate2D(latitude: obj["latitude"] as! Double, longitude: obj["longitude"] as! Double)
                
                coordinates.append(centerLocation)
            }
            
            let sortedCoordinates = coordinates.map({CLLocation(latitude: $0.latitude, longitude: $0.longitude)}).sorted(by: {
                $0.distance(from: currentLocation) < $1.distance(from: currentLocation)
            })
            for coord in sortedCoordinates {
                for spot in spots {
                    
                    let obj = spot as! Dictionary<String, Any>
                    if (obj["longitude"] as! Double == coord.coordinate.longitude && obj["latitude"] as! Double  == coord.coordinate.latitude) {
                        self.citySpots.append(obj)
                    }
                }
            }
            self.spotOrder = spots as! [Dictionary<String, Any>]
            // use city and spotNum to get the image
            // Get a reference to the storage service using the default Firebase App
            let storage = Storage.storage()
            // Create a storage reference from our storage service
            let storageRef = storage.reference()
            for spot in self.citySpots {
                let spotNum = self.getSpotNum(currentSpot: spot)
                self.photoNumbers.append(spotNum)
                // Create a reference to the file you want to download
                let imageRef = storageRef.child("images/\(currentCity.city)/\(spotNum).JPG")
                
                // Download in memory with a maximum allowed size of 30MB (30 * 1024 * 1024 bytes)
                imageRef.getData(maxSize: 30 * 1024 * 1024) { data, error in
                    if error != nil {
                        print(error!)
                    } else {
                        // Data for image is returned
                        let image = UIImage(data: data!)
                        self.citySpotPhotos[self.photoNumbers.index(of: spotNum)!] = image!
                    }
                    self.closestSpotsTableView.reloadData()
                }
            }
            self.closestSpotsTableView.reloadData()
        }) { (error) in
            print(error.localizedDescription)
        }
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
     Informs the table view delegate that the table view is about to display a cell for a particular row.
     Just before the cell is displayed, we change the cell's background color as MINT_CREAM for even-numbered rows
     and OLD_LACE for odd-numbered rows to improve the table view's readability.
     */
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        /*
         The remainder operator (RowNumber % 2) computes how many multiples of 2 will fit inside RowNumber
         and returns the value, either 0 or 1, that is left over (known as the remainder).
         Remainder 0 implies even-numbered rows; Remainder 1 implies odd-numbered rows.
         */
        if indexPath.row % 2 == 0 {
            // Set even-numbered row's background color to MintCream, #F5FFFA 245,255,250
            cell.backgroundColor = MINT_CREAM
            
        } else {
            // Set odd-numbered row's background color to OldLace, #FDF5E6 253,245,230
            cell.backgroundColor = OLD_LACE
        }
    }
    
    /*
     -----------------------------------
     MARK: - Table View Delegate Methods
     -----------------------------------
     */
    
    // Asks the table view delegate to return the height of a given row.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return tableViewRowHeight
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
    
    //---------------------------
    // Spot (Row) Selected
    //---------------------------
    
    // Tapping a row (spot) gives directions to said spot
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let rowNumber = (indexPath as NSIndexPath).row
        
        let givenSpot = citySpots[rowNumber]
        let spotLat = givenSpot["latitude"]
        let spotLong = givenSpot["longitude"]
        coordinateToPass = "\(spotLat!)" + "," + "\(spotLong!)"
        
        performSegue(withIdentifier: "GetDirections", sender: self)
    }
    
    /*
     -------------------------
     MARK: - Prepare For Segue
     -------------------------
     */
    
    // This method is called by the system whenever you invoke the method performSegueWithIdentifier:sender:
    // You never call this method. It is invoked by the system.
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if segue.identifier == "GetDirections" {
            // Obtain the object reference of the destination (downstream) view controller
            let directionsViewController: DirectionsViewController = segue.destination as! DirectionsViewController
            
            directionsViewController.selectedLocationName = coordinateToPass
        }
    }
}
