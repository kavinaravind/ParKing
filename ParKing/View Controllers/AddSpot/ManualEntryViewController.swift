//
//  ManualEntryViewController.swift
//  ParKing
//
//  Created by CS3714 on 4/28/18.
//  Copyright © 2018 Group 10. All rights reserved.
//

import UIKit
import CoreLocation

class ManualEntryViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate {

    // Instance variable holding the object reference of the objects created in the Storyboard
    @IBOutlet var vacancySegmentedControl: UISegmentedControl!
    @IBOutlet var timeLimitPickerView: UIPickerView!
    @IBOutlet var electricVehicleSegmentedControl: UISegmentedControl!
    @IBOutlet var spotCostTextField: UITextField!
    @IBOutlet var spotTypeSegmentedControl: UISegmentedControl!
    @IBOutlet var securitySegmentedControl: UISegmentedControl!
    @IBOutlet var payPalSwitch: UISwitch!
    @IBOutlet var cashSwitch: UISwitch!
    @IBOutlet var coinSwitch: UISwitch!
    @IBOutlet var cardSwitch: UISwitch!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var retakePhotoButton: UIButton!
    @IBOutlet var photoImageView: UIImageView!
    @IBOutlet var pictureLabel: UILabel!
    @IBOutlet var takePhotoButton: UIButton!
    
    // Instance variable to hold the object reference of a Text Field object
    var activeTextField: UITextField?
    
    //Picker control for the camera image
    var imagePicker: UIImagePickerController!
    
    //Create the dictionary to pass to the confirmation screen
    var spotDataToPass = Dictionary<String, AnyObject>()
    var latitudeToPass: Double?
    var longitudeToPass: Double?
    // Instantiate a CLLocationManager object
    var locationManager = CLLocationManager()
    var userAuthorizedLocationMonitoring = false
    
    //SetUp string array for picker
    let timeLimit = ["15 Minutes", "30 Minutes", "45 Minutes", "1 Hour", "2 Hours", "3 Hours", "4 Hours", "5 Hours", "6 Hours", "12 Hours", "1 Day", "Unlimited"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        // Make sure all the segment controls default to no selection
        electricVehicleSegmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment
        spotTypeSegmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment
        securitySegmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment
        vacancySegmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment
        //Make all the switches unselected
        payPalSwitch.setOn(false, animated: false)
        cashSwitch.setOn(false, animated: false)
        coinSwitch.setOn(false, animated: false)
        cardSwitch.setOn(false, animated: false)
        photoImageView.isHidden = true
        retakePhotoButton.isHidden = true
        retakePhotoButton.isEnabled = false
        
        // Designate self as a subscriber to Keyboard Notifications
        
        registerForKeyboardNotifications()
    }
    
    /*
     ---------------------------
     MARK: - Unwind Segue Method
     ---------------------------
     */
    @IBAction func unwindToManualEntryViewController(segue : UIStoryboardSegue) {
        if segue.identifier != "EditSpot" {
            return
        }
        
        // Obtain the object reference of the source view controller
        let confirmAddViewController: ConfirmAddViewController = segue.source as! ConfirmAddViewController
        
        // get the data from the spot confirmation so you can set the variables of the manual add screen
        photoImageView.image = confirmAddViewController.spotPictureImageView.image
        takePhotoButton.isHidden = true
        takePhotoButton.isEnabled = false
        pictureLabel.isHidden = true
        photoImageView.isHidden = false
        retakePhotoButton.isHidden = false
        retakePhotoButton.isEnabled = true
        
        //Set vacancy
        let vacancy: String = confirmAddViewController.vacancyLabel.text!
        if vacancy == "Spot Taken" {
            vacancySegmentedControl.selectedSegmentIndex = 1
        }
        else {
            vacancySegmentedControl.selectedSegmentIndex = 0
        }
        //Set picker limit
        let limit: String = confirmAddViewController.timeLimitLabel.text!
        let pickerIndex = timeLimit.index(of: limit)
        timeLimitPickerView.selectRow(pickerIndex!, inComponent: 0, animated: false)
        //Set Electric vehicle
        let electric: String = confirmAddViewController.electricVehicleLabel.text!
        if electric == "Yes" {
            electricVehicleSegmentedControl.selectedSegmentIndex = 0
        }
        else {
            electricVehicleSegmentedControl.selectedSegmentIndex = 1
        }
        //Set cost
        spotCostTextField.text = confirmAddViewController.costLabel.text!
        //Set spot type
        let type: String = confirmAddViewController.spotTypeLabel.text!
        if type == "Parallel" {
            spotTypeSegmentedControl.selectedSegmentIndex = 0
        }
        else if type == "Pull-In" {
            spotTypeSegmentedControl.selectedSegmentIndex = 1
        }
        else {
            spotTypeSegmentedControl.selectedSegmentIndex = 2
        }
        //Set security
        let security: String = confirmAddViewController.securityLabel.text!
        if security == "Yes" {
            securitySegmentedControl.selectedSegmentIndex = 0
        }
        else {
            securitySegmentedControl.selectedSegmentIndex = 1
        }
        //Set payment methods
        let payment: String = confirmAddViewController.paymentMethodsLabel.text!
        if payment.range(of: "PayPal") != nil {
            payPalSwitch.isOn = true
        }
        if payment.range(of: "Cash") != nil {
            cashSwitch.isOn = true
        }
        if payment.range(of: "Coin") != nil {
            coinSwitch.isOn = true
        }
        if payment.range(of: "Card") != nil {
            cardSwitch.isOn = true
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Obtain the number of the row in the middle of the time limit names list
        let numberOfRowToShow = Int(timeLimit.count / 2)
        
        // Show the picker view of the time limits from the middle
        timeLimitPickerView.selectRow(numberOfRowToShow, inComponent: 0, animated: false)
        
        self.registerForKeyboardNotifications()
        
    }
    
    /*
     -----------------------------------------------
     MARK: - UIPickerViewDataSource Protocol Methods
     -----------------------------------------------
     */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return timeLimit.count
    }
    
    /*
     --------------------------------------------
     MARK: - UIPickerViewDelegate Protocol Method
     --------------------------------------------
     */
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return timeLimit[row]
    }
    
    /*
     --------------------------
     MARK: - Add Button Tapped
     --------------------------
     */
    @IBAction func addButtonTapped(_ sender: UIBarButtonItem) {
        
        //Make sure segments were selected for the segment controls
        if vacancySegmentedControl.selectedSegmentIndex == UISegmentedControlNoSegment {
            showAlertMessage(messageHeader: "Form Not Complete", messageBody: "Please select a segment for the vacancy of the spot!")
            return
        }
        if electricVehicleSegmentedControl.selectedSegmentIndex == UISegmentedControlNoSegment {
            showAlertMessage(messageHeader: "Form Not Complete", messageBody: "Please select a segment for the electric vehicle status of the spot!")
            return
        }
        if spotTypeSegmentedControl.selectedSegmentIndex == UISegmentedControlNoSegment {
            showAlertMessage(messageHeader: "Form Not Complete", messageBody: "Please select a segment for the spot type!")
            return
        }
        if securitySegmentedControl.selectedSegmentIndex == UISegmentedControlNoSegment {
            showAlertMessage(messageHeader: "Form Not Complete", messageBody: "Please select a segment for the security status of the spot!")
            return
        }
        if photoImageView.isHidden == true {
            showAlertMessage(messageHeader: "Form Not Complete", messageBody: "Please take a photo of the spot!")
            return
        }
        
        //Get the image for the spot
        spotDataToPass["image"] = photoImageView.image as AnyObject
        
        //Get the Time Limit for the Spot
        let index = timeLimitPickerView.selectedRow(inComponent: 0)
        let timeLimitForSpot = timeLimit[index]
        
        let spotCost = spotCostTextField.text
        if spotCost == "" {
            showAlertMessage(messageHeader: "Form Not Complete", messageBody: "Please enter a spot cost in the relevant text field!")
            return
        }
        
        let hasPayPal = payPalSwitch.isOn
        let hasCash = cashSwitch.isOn
        let hasCoin = coinSwitch.isOn
        let hasCard = cardSwitch.isOn
        if (!hasPayPal && !hasCard && !hasCoin && !hasCash) {
            showAlertMessage(messageHeader: "Form Not Complete", messageBody: "Please select at least one payment method from the options!")
            return
        }
        
        //Add the spot vacancy
        switch vacancySegmentedControl.selectedSegmentIndex {
            
        case 0:
            spotDataToPass["availability"] = true as AnyObject
            
        case 1:
            spotDataToPass["availability"] = false as AnyObject
            
        default:
            return
        }
        //Add the spot time limit
        spotDataToPass["timeLimit"] = timeLimitForSpot as AnyObject
        //Add the spot electric vehicle status
        switch electricVehicleSegmentedControl.selectedSegmentIndex {
            
        case 0:
            spotDataToPass["electricVehicle"] = true as AnyObject
            
        case 1:
            spotDataToPass["electricVehicle"] = false as AnyObject
            
        default:
            return
        }
        //Add the spot cost
        spotDataToPass["cost"] = spotCost as AnyObject
        //Add the spot type
        switch spotTypeSegmentedControl.selectedSegmentIndex {
            
        case 0:
            spotDataToPass["spotType"] = "Parallel" as AnyObject
            
        case 1:
            spotDataToPass["spotType"] = "Pull-In" as AnyObject
            
        case 2:
            spotDataToPass["spotType"] = "Garage" as AnyObject
            
        default:
            return
        }
        //Add the security status
        switch securitySegmentedControl.selectedSegmentIndex {
            
        case 0:
            spotDataToPass["hasSecurity"] = true as AnyObject
            
        case 1:
            spotDataToPass["hasSecurity"] = false as AnyObject
            
        default:
            return
        }
        //Add the payment methods
        spotDataToPass["payPal"] = hasPayPal as AnyObject
        spotDataToPass["cash"] = hasCash as AnyObject
        spotDataToPass["coin"] = hasCoin as AnyObject
        spotDataToPass["card"] = hasCard as AnyObject
        //Add lat/long
        spotDataToPass["latitude"] = latitudeToPass as AnyObject
        spotDataToPass["longitude"] = longitudeToPass as AnyObject
        performSegue(withIdentifier: "ConfirmSpot", sender: self)
    }
    
    /*
     -----------------------------
     MARK: - Take Photo
     -----------------------------
     */
    @IBAction func takePhoto(sender: UIButton) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        
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
        
        //Take the photp
        present(imagePicker, animated: true, completion: nil)
        takePhotoButton.isHidden = true
        takePhotoButton.isEnabled = false
        pictureLabel.isHidden = true
        photoImageView.isHidden = false
        retakePhotoButton.isHidden = false
        retakePhotoButton.isEnabled = true
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
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        photoImageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
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
     -------------------------
     MARK: - Prepare for Segue
     -------------------------
     
     This method is called by the system whenever you invoke the method performSegueWithIdentifier:sender:
     You never call this method. It is invoked by the system.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if segue.identifier == "ConfirmSpot" {
            // Obtain the object reference of the destination (downstream) view controller
            let confirmAddViewController: ConfirmAddViewController = segue.destination as! ConfirmAddViewController
            
            confirmAddViewController.dataObjectPassed = spotDataToPass
        }
    }
    
    /*
     -----------------------------------------
     MARK: - Content View in Original Position
     -----------------------------------------
     */
    func setContentViewToItsOriginalPosition() {
        
        // Set contentInsets to top=0, left=0, bottom=0, and right=0
        let contentInsets: UIEdgeInsets = UIEdgeInsets.zero
        
        // Set scrollView's contentInsets to top=0, left=0, bottom=0, and right=0
        scrollView.contentInset = contentInsets
        
        // Set scrollView's scrollIndicatorInsets to top=0, left=0, bottom=0, and right=0
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    /*
     ---------------------------------------
     MARK: - Handling Keyboard Notifications
     ---------------------------------------
     */
    
    // This method is called in viewDidLoad() to register self for keyboard notifications
    func registerForKeyboardNotifications() {
        
        // "A NotificationCenter object (or simply, notification center) provides a
        // mechanism for broadcasting information within a program." [Apple]
        
        // Obtain the object reference of the default notification center
        let notificationCenter = NotificationCenter.default
        
        // Add self as an Observer for the "Keyboard Will Show" notification by specifying
        // the name of the method to invoke upon that notification.
        notificationCenter.addObserver(self,
                                       selector:   #selector(ManualEntryViewController.keyboardWillShow(_:)),    // <-- Call this method upon Keyboard Will SHOW Notification
            name:       NSNotification.Name.UIKeyboardWillShow,
            object:     nil)
        
        // Add self as an Observer for the "Keyboard Will Hide" notification by specifying
        // the name of the method to invoke upon that notification.
        notificationCenter.addObserver(self,
                                       selector:   #selector(ManualEntryViewController.keyboardWillHide(_:)),    //  <-- Call this method upon Keyboard Will HIDE Notification
            name:       NSNotification.Name.UIKeyboardWillHide,
            object:     nil)
    }
    
    // This method is called upon the "Keyboard Will Show" notification
    @objc func keyboardWillShow(_ sender: Notification) {
        
        // "userInfo, the user information dictionary stores any additional
        // objects that objects receiving the notification might use." [Apple]
        let info: NSDictionary = (sender as NSNotification).userInfo! as NSDictionary
        
        /*
         Key     = UIKeyboardFrameEndUserInfoKey
         Value   = an NSValue object containing a CGRect that identifies the start frame of the keyboard in screen coordinates.
         */
        let value: NSValue = info.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        
        // Obtain the size of the keyboard
        let keyboardSize: CGSize = value.cgRectValue.size
        
        // Create Edge Insets for the view.
        // UIEdgeInsetsMake(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right);
        let contentInsets: UIEdgeInsets = UIEdgeInsetsMake(64.0, 0.0, keyboardSize.height, 0.0)
        
        // Set the distance that the content view is inset from the enclosing scroll view.
        scrollView.contentInset = contentInsets
        
        // Set the distance the scroll indicators are inset from the edge of the scroll view.
        scrollView.scrollIndicatorInsets = contentInsets
        
        //-----------------------------------------------------------------------------------
        // If active text field is hidden by keyboard, scroll the content up so it is visible
        //-----------------------------------------------------------------------------------
        
        // Obtain the frame size of the View
        var selfViewFrameSize: CGRect = self.view.frame
        
        // Subtract the keyboard height from the self's view height
        // and set it as the new height of the self's view
        selfViewFrameSize.size.height -= keyboardSize.height
        
        // Obtain the size of the active UITextField object
        let activeTextFieldRect: CGRect? = activeTextField!.frame
        
        // Obtain the active UITextField object's origin (x, y) coordinate
        let activeTextFieldOrigin: CGPoint? = activeTextFieldRect?.origin
        
        if (!selfViewFrameSize.contains(activeTextFieldOrigin!)) {
            
            // If active UITextField object's origin is not contained within self's View Frame,
            // then scroll the content up so that the active UITextField object is visible
            
            scrollView.scrollRectToVisible(activeTextFieldRect!, animated:true)
        }
    }
    
    // This method is called upon the "Keyboard Will Hide" notification
    @objc func keyboardWillHide(_ sender: Notification) {
        
        // Set contentInsets to top=0, left=0, bottom=0, and right=0
        let contentInsets: UIEdgeInsets = UIEdgeInsets.zero
        
        // Set scrollView's contentInsets to top=0, left=0, bottom=0, and right=0
        scrollView.contentInset = contentInsets
        
        // Set scrollView's scrollIndicatorInsets to top=0, left=0, bottom=0, and right=0
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    /*
     ------------------------------------
     MARK: - UITextField Delegate Methods
     ------------------------------------
     */
    
    // This method is called when the user taps inside a text field
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        activeTextField = textField
    }
    
    /*
     This method is called when the user:
     (1) selects another UI object after editing in a text field
     (2) taps Return on the keyboard
     */
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        activeTextField = nil
        
        // Process the Text Entered by the User Here
    }
    
    // This method is called when the user taps Return on the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        // Deactivate the text field and remove the keyboard
        textField.resignFirstResponder()
        
        // Bring the Content View back to its original position
        setContentViewToItsOriginalPosition()
        
        return true
    }
    
    /*
     ---------------------------------------------
     MARK: - Register and Unregister Notifications
     ---------------------------------------------
     */
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    /*
     ------------------------
     MARK: - IBAction Methods
     ------------------------
     */
    @IBAction func keyboardDone(_ sender: UITextField) {
        
        // When the Text Field resigns as first responder, the keyboard is automatically removed.
        sender.resignFirstResponder()
    }
    
    @IBAction func backgroundTouch(_ sender: UIControl) {
        /*
         "This method looks at the current view and its subview hierarchy for the text field that is
         currently the first responder. If it finds one, it asks that text field to resign as first responder.
         If the force parameter is set to true, the text field is never even asked; it is forced to resign." [Apple]
         
         When the Text Field resigns as first responder, the keyboard is automatically removed.
         */
        view.endEditing(true)
    }

}
