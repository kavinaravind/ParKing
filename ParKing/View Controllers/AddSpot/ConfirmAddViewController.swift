//
//  ConfirmAddViewController.swift
//  ParKing
//
//  Created by CS3714 on 4/28/18.
//  Copyright © 2018 Group 10. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

class ConfirmAddViewController: UIViewController {

    // Instance variable holding the object reference of the objects created in the Storyboard
    @IBOutlet var spotPictureImageView: UIImageView!
    @IBOutlet var vacancyLabel: UILabel!
    @IBOutlet var timeLimitLabel: UILabel!
    @IBOutlet var electricVehicleLabel: UILabel!
    @IBOutlet var costLabel: UILabel!
    @IBOutlet var spotTypeLabel: UILabel!
    @IBOutlet var securityLabel: UILabel!
    @IBOutlet var paymentMethodsLabel: UILabel!
    
    var ref: DatabaseReference!
    
    //Dictionary of data passed from add spot screen
    var dataObjectPassed = [String: Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the A edit button on the left of the navigation bar to call the edit spot method when tapped
        let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self,
                                                         action: #selector(ConfirmAddViewController.editSpot(_:)))
        self.navigationItem.leftBarButtonItem = editButton
        
        //Set the image
        spotPictureImageView.image = dataObjectPassed["image"] as? UIImage
        if (dataObjectPassed["qr"] != nil) {
            spotPictureImageView.transform = spotPictureImageView.transform.rotated(by: CGFloat(Double.pi / 2))
            dataObjectPassed.removeValue(forKey: "qr")
        }
        
        //Set the labels
        if (dataObjectPassed["availability"] as! Bool) {
            vacancyLabel.text = "Spot Open"
        }
        else {
            vacancyLabel.text = "Spot Taken"
        }
        timeLimitLabel.text = dataObjectPassed["timeLimit"] as? String
        if (dataObjectPassed["electricVehicle"] as! Bool) {
            electricVehicleLabel.text = "Yes"
        }
        else {
            electricVehicleLabel.text = "No"
        }
        costLabel.text = dataObjectPassed["cost"] as? String
        spotTypeLabel.text = dataObjectPassed["spotType"] as? String
        if (dataObjectPassed["hasSecurity"] as! Bool) {
            securityLabel.text = "Yes"
        }
        else {
            securityLabel.text = "No"
        }
        var paymentMethodsText = ""
        if dataObjectPassed["payPal"] as! Bool {
            paymentMethodsText += "PayPal"
        }
        if dataObjectPassed["cash"] as! Bool {
            if dataObjectPassed["payPal"] as! Bool {
                paymentMethodsText += ", Cash"
            }
            else {
                paymentMethodsText += "Cash"
            }
        }
        if dataObjectPassed["coin"] as! Bool {
            if (dataObjectPassed["payPal"] as! Bool || dataObjectPassed["cash"] as! Bool) {
                paymentMethodsText += ", Coin"
            }
            else {
                paymentMethodsText += "Coin"
            }
        }
        if dataObjectPassed["card"] as! Bool {
            if (dataObjectPassed["payPal"] as! Bool || dataObjectPassed["cash"] as! Bool || dataObjectPassed["coin"] as! Bool) {
                paymentMethodsText += ", Card"
            }
            else {
                paymentMethodsText += "Card"
            }
        }
        paymentMethodsLabel.text = paymentMethodsText
    }

    /*
     ---------------------------
     MARK: - Edit Spot
     ---------------------------
     */
    
    // The editSpot method is invoked when the user taps the Edit button created in viewDidLoad() above.
    @objc func editSpot(_ sender: AnyObject) {
        
        // Perform the segue
        performSegue(withIdentifier: "EditSpot", sender: self)
    }
    
    /*
     --------------------------
     MARK: - Confirm Button Tapped
     --------------------------
     */
    @IBAction func confirmButtonTapped(_ sender: UIBarButtonItem) {
        //if its a manual entry add an image to the db
        var imageIdx = 0
        // Write the image to storage
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        ref = Database.database().reference()
        ref.child(currentCity.city).observeSingleEvent(of: .value, with: { (snapshot) in
            let spots: [Any] = snapshot.value as! [Any]
            imageIdx = spots.count
            //Create image data
            let imageData: Data = UIImagePNGRepresentation((self.dataObjectPassed["image"] as? UIImage)!)!
            
            // Create a reference to the file you want to upload
            let cityImageRef = storageRef.child("images/\(currentCity.city)/\(imageIdx).JPG")
            
            // Upload the file to the path
            _ = cityImageRef.putData(imageData, metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                    // Uh-oh, an error occurred!
                    return
                }
                // Metadata contains file metadata such as size, content-type, and download URL.
                _ = metadata.downloadURL
            }
        }) { (error) in
            print(error.localizedDescription)
        }
        // Write data to firebase
        ref = Database.database().reference()
        ref.child(currentCity.city).observeSingleEvent(of: .value, with: { (snapshot) in
            
            var spots: [Any] = snapshot.value as! [Any]
            self.dataObjectPassed.removeValue(forKey: "image")
            spots.append(self.dataObjectPassed)
            self.ref.child(currentCity.city).setValue(spots)

        }) { (error) in
            print(error.localizedDescription)
        }
        //Exit back to add spot screen
        performSegue(withIdentifier: "SpotConfirmed", sender: self)
    }
    
    /*
     -------------------------
     MARK: - Prepare for Segue
     -------------------------
     
     This method is called by the system whenever you invoke the method performSegueWithIdentifier:sender:
     You never call this method. It is invoked by the system.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if segue.identifier == "SpotConfirmed" {
            // Obtain the object reference of the destination (downstream) view controller
            let addSpotViewController: AddSpotViewController = segue.destination as! AddSpotViewController
            
            addSpotViewController.navigationItem.hidesBackButton = true
        }
    }
    
}
