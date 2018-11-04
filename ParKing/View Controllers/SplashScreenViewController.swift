//
//  SplashScreenViewController.swift
//  ParKing
//
//  Created by CS3714 on 4/18/18.
//  Copyright © 2018 Group 10. All rights reserved.
//

import UIKit
import LocalAuthentication

class SplashScreenViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // Instance variables holding the object references of the UI objects created in the Storyboard
    @IBOutlet var cityPickerView: UIPickerView!
    
    //The Array of all the city names
    let cityNames = ["Blacksburg, VA", "New York, NY", "Los Angeles, CA", "San Francisco, CA", "Washington, DC", "Seattle, WA", "Chicago, IL" ]
    
    // Data to pass to downstream view controller
    var citySelected = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Obtain the number of the row in the middle of the list
        let numberOfCities = cityNames.count
        let numberOfRowToShow = Int(numberOfCities / 2)
        
        // Show the picker view of VT place names from the middle
        cityPickerView.selectRow(numberOfRowToShow, inComponent: 0, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     ------------------------
     MARK: - IBAction Methods
     ------------------------
     */
    
    @IBAction func citySelectButtonTapped(_ sender: UIButton) {
        authenticateUser()
    }
    
    @IBAction func noCityButtonTapped(_ sender: UIButton) {
        // Perform the segue named CityNotFound
        performSegue(withIdentifier: "CityNotFound", sender: self)
    }
    
    /*
     ----------------------------------------
     MARK: - UIPickerView Data Source Methods
     ----------------------------------------
     */
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return cityNames.count
    }
    
    /*
     ------------------------------------
     MARK: - UIPickerView Delegate Method
     ------------------------------------
     */
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return cityNames[row]
    }
    
    /*
     ------------------------------------
     MARK: - Authentication Methods
     ------------------------------------
     */
    func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log In"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [unowned self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        //Continue
                        let selectedRowNumber = self.cityPickerView.selectedRow(inComponent: 0)
                        self.citySelected = self.cityNames[selectedRowNumber]
                        currentCity.city = self.citySelected
                        // Perform the segue named CityFound
                        self.performSegue(withIdentifier: "CityFound", sender: self)
                    } else {
                        let message: String
                        
                        switch authenticationError {
                            case LAError.authenticationFailed?:
                                message = "There was a problem verifying your identity."
                            case LAError.userCancel?:
                                message = "You pressed cancel."
                            case LAError.userFallback?:
                                message = "You pressed password."
                            case LAError.biometryNotAvailable?:
                                message = "Face ID/Touch ID is not available."
                            case LAError.biometryNotEnrolled?:
                                message = "Face ID/Touch ID is not set up."
                            case LAError.biometryLockout?:
                                message = "Face ID/Touch ID is locked."
                            default:
                                message = "Face ID/Touch ID may not be configured"
                        }
                        self.showAlertMessage(messageTitle: "Authentication Failed", messageContent: message)
                    }
                }
            }
        } else {
            showAlertMessage(messageTitle: "Touch ID not available", messageContent: "Your device is not configured for Touch ID.")
        }
    }
    
    /*
     --------------------------
     MARK: - Show Alert Message
     --------------------------
     */
    func showAlertMessage(messageTitle: String, messageContent: String) {
        /*
         Create a UIAlertController object; dress it up with title, message, and preferred style;
         and store its object reference into local constant alertController
         */
        let alertController = UIAlertController(title: messageTitle, message: messageContent, preferredStyle: .alert)
        
        // Create a UIAlertAction object and add it to the alert controller
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        
        // Present the alert controller
        present(alertController, animated: true, completion: nil)
    }
}
