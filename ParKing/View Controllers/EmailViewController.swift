//
//  EmailViewController.swift
//  ParKing
//
//  Created by CS3714 on 4/29/18.
//  Copyright © 2018 Group 10. All rights reserved.
//

import UIKit
import Foundation
import MessageUI

class EmailViewController: UIViewController, MFMailComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /*
     -------------------------------
     MARK: - Email Button Tapped
     -------------------------------
     */
    @IBAction func emailButtonTapped(_ sender: UIButton) {
        if MFMailComposeViewController.canSendMail() {
            let composeEmail = MFMailComposeViewController()
            composeEmail.mailComposeDelegate = self
            // Configure the fields of the interface.
            composeEmail.setToRecipients(["sandrew2@vt.edu"])
            composeEmail.setSubject("Add ParKing to My City!")
            composeEmail.setMessageBody("Hello,\n We would like to see ParKing come to (Insert City Here)! Hope to see you soon! \nFrom, \n(Insert Name Here)", isHTML: true)
            // Present the view controller modally.
            self.present(composeEmail, animated: true, completion: nil)
        }
        else {
            showAlertMessage(messageTitle: "Mail Service Error", messageContent: "Mail service is currently unavailable, please try again later.")
            return
        }
    }
    
    //Mail composer delegate, dismisses email window when done
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
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
