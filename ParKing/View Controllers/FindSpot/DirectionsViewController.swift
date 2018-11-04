//
//  DirectionsViewController.swift
//  ParKing
//
//  Created by CS3714 on 4/30/18.
//  Copyright © 2018 Group 10. All rights reserved.
//

import UIKit
import WebKit

class DirectionsViewController: UIViewController, WKNavigationDelegate {

    // Instance variable holding the object reference of the WebKit View object.
    @IBOutlet var webView: WKWebView!
    
    // The value of this instance variable is set by the upstream view controller (TableViewController) object.
    var selectedLocationName: String = ""
    
    /*
     -----------------------
     MARK: - View Life Cycle
     -----------------------
     */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         Set self (UIViewController object) to be the webView (WKWebView) object's navigation delegate
         so that we can implement the three WKNavigationDelegate protocol methods given below.
         */
        webView.navigationDelegate = self
        
        // Set this view's title to be the selected country name
        // self.title = selectedLocationName
        
        /*
         We compose a Google Maps API query by using the selected location name.
         We ask the webView object to send the query to Google Maps API, obtain the map, and display it.
         The query cannot contain spaces. Therefore, we replace all spaces in a country name, if any, with "+".
         */
        let selectedLocationNameWithNoSpaces = selectedLocationName.replacingOccurrences(of: " ", with: "+", options: [], range: nil)
        
        /*
         Convert the Google Maps API query string into an NSURL object and store its object
         reference into the local variable url. An NSURL object represents a URL.
         */
        print (selectedLocationNameWithNoSpaces)
        let url = URL(string: "https://www.google.com/maps/place/" + selectedLocationNameWithNoSpaces)
        
        if (url == nil) {
            showAlertMessage(messageHeader: "Unable to Display Map", messageBody: "Selected location name has special characters preventing the display of its map!")
            return
        }
        
        /*
         Convert the NSURL object into an NSURLRequest object and store its object
         reference into the local variable request. An NSURLRequest object represents
         a URL load request in a manner independent of protocol and URL scheme.
         */
        let request = URLRequest(url: url!)
        
        // Ask the webView object to fetch and display the map of the selected country
        webView.load(request)
    }
    
    /*
     ---------------------------------------------
     MARK: - WKNavigationDelegate Protocol Methods
     ---------------------------------------------
     */
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Starting to load the web page. Show the animated activity indicator in the status bar
        // to indicate to the user that the UIWebVIew object is busy loading the web page.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Finished loading the web page. Hide the activity indicator in the status bar.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        /*
         Ignore this error if the page is instantly redirected via JavaScript or in another way.
         NSURLErrorCancelled is returned when an asynchronous load is cancelled, which happens
         when the page is instantly redirected via JavaScript or in another way.
         */
        
        if (error as NSError).code == NSURLErrorCancelled {
            return
        }
        
        // An error occurred during the web page load. Hide the activity indicator in the status bar.
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        // Create the error message in HTML as a character string and store it into the local constant errorString
        let errorString = "<html><font size=+4 color='red'><p>Unable to Display Webpage: <br />Possible Causes:<br />- No network connection<br />- Wrong URL entered<br />- Server computer is down</p></font></html>" + error.localizedDescription
        
        // Display the error message within the webView object
        self.webView.loadHTMLString(errorString, baseURL: nil)
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

}
