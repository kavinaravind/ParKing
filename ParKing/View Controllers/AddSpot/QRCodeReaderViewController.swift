//
//  QRCodeReaderViewController.swift
//  ParKing
//
//  Created by CS3714 on 4/18/18.
//  Copyright © 2018 Group 10. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseStorage

class QRCodeReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    /*
     Create an AVCaptureSession object and store its object reference into "avCaptureSession" constant.
     AVCaptureSession object is used to coordinate the flow of data from AV input devices to outputs.
     */
    let avCaptureSession = AVCaptureSession()
    
    /*
     "AVCaptureVideoPreviewLayer is a subclass of CALayer that you use to display video
     as it is being captured by an input device.
     */
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    // Declare an instance variable to hold the object reference of a UIImageView object
    var scanningRegionView: UIImageView!
    
    // Declare an instance variable to hold the object reference of a UIImageView object
    var scanningCompleteView: UIImageView!
    
    //Dictionary of data passed from add spot screen
    var dataObjectToPass = [String: Any]()
    
    // Instance variables
    var viewWidth: CGFloat = 0.0
    var viewHeight: CGFloat = 0.0
    var edge: CGFloat = 0.0
    var qrCodeRead = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewHeight = view.frame.height
        viewWidth = view.frame.width
        edge = viewWidth * 0.7
        
        constructScanningRegionView()
        
        constructScanningCompleteView()
        
        // Set the default AV Capture Device to capture data of media type video
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let captureDeviceInput: AVCaptureDeviceInput? = try AVCaptureDeviceInput(device: captureDevice!) as AVCaptureDeviceInput
            
            // AV Capture input device is initialized and ready
            avCaptureSession.addInput(captureDeviceInput!)
            
        } catch let error as NSError {
            // An NSError object contains detailed error information than is possible using only an error code or error string
            
            // AV Capture input device failed to be available
            
            /*
             Create a UIAlertController object; dress it up with title, message, and preferred style;
             and store its object reference into local constant alertController
             */
            let alertController = UIAlertController(title: "AVCaptureDeviceInput Failed!",
                                                    message: "An error occurred during AV capture device input: \(error)",
                preferredStyle: UIAlertControllerStyle.alert)
            
            // Create a UIAlertAction object and add it to the alert controller
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            // Present the alert controller by calling the presentViewController method
            present(alertController, animated: true, completion: nil)
            
            return
        }
        
        /*
         Create an AVCaptureMetadataOutput object and store its object reference into local constant "output".
         "An AVCaptureMetadataOutput object intercepts metadata objects emitted by its associated capture
         connection and forwards them to a delegate object for processing."
         */
        let output = AVCaptureMetadataOutput()
        
        /*
         Set self to be the delegate to notify when new metadata objects become available.
         Set dispatch queue on which to execute the delegate’s methods.
         */
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        // Set the rectangle of interest to match the bounding box we drew above
        output.rectOfInterest = CGRect(x: (viewHeight * 0.5 - edge / 2) / viewHeight, y: 0.15, width: edge / viewHeight, height: 0.7)
        
        avCaptureSession.addOutput(output)
        output.metadataObjectTypes = output.availableMetadataObjectTypes
        
        // Add a preview so the user can see what the camera is detecting
        previewLayer = AVCaptureVideoPreviewLayer(session: avCaptureSession) as AVCaptureVideoPreviewLayer
        
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Move the scanningRegionView subview so that it appears on top of its siblings
        view.bringSubview(toFront: scanningRegionView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // Start the AV Capture Session running. It will run until it is stopped later.
        avCaptureSession.startRunning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // Move the scanningCompleteView subview so that it appears behind its siblings
        self.view.sendSubview(toBack: scanningCompleteView)
    }
    
    /*
     --------------------------------------
     MARK: - Construct Scanning Region View
     --------------------------------------
     */
    func constructScanningRegionView() {
        
        // Create an image view object to show the entire view frame as the scanning region
        scanningRegionView = UIImageView(frame: view.frame)
        
        // Create a bitmap-based graphics context as big as the scanning region and make it the Current Context
        UIGraphicsBeginImageContext(scanningRegionView.frame.size)
        
        // Draw the entire image in the specified rectangle, which is the entire view frame (scanning region)
        scanningRegionView.image?.draw(in: CGRect(x: 0, y: 0, width: scanningRegionView.frame.width, height: scanningRegionView.frame.height))
        
        //-------------------------------------------
        //         Draw the Left Bracket
        //-------------------------------------------
        
        UIGraphicsGetCurrentContext()?.move(to: CGPoint(x:  viewWidth * 0.20, y: viewHeight * 0.5 - edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:  viewWidth * 0.15, y: viewHeight * 0.5 - edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:   viewWidth * 0.15, y: viewHeight * 0.5 + edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:   viewWidth * 0.20, y: viewHeight * 0.5 + edge / 2))
        
        
        //-------------------------------------------
        //         Draw the Right Bracket
        //-------------------------------------------
        
        UIGraphicsGetCurrentContext()?.move(to: CGPoint(x:  viewWidth * 0.8, y: viewHeight * 0.5 - edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:  viewWidth * 0.85, y: viewHeight * 0.5 - edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:   viewWidth * 0.85, y: viewHeight * 0.5 + edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:   viewWidth * 0.8, y: viewHeight * 0.5 + edge / 2))
        
        //-------------------------------------------
        //    Set Properties of the Bracket Lines
        //-------------------------------------------
        
        // Set the bracket lines with a squared-off end
        UIGraphicsGetCurrentContext()?.setLineCap(CGLineCap.butt)
        
        // Set the bracket line width to 5
        UIGraphicsGetCurrentContext()?.setLineWidth(5)
        
        // Set the bracket line color to red
        UIGraphicsGetCurrentContext()?.setStrokeColor(UIColor.red.cgColor)
        
        // Set the bracket line blend mode to be normal
        UIGraphicsGetCurrentContext()?.setBlendMode(CGBlendMode.normal)
        
        // Set the bracket line stroke path
        UIGraphicsGetCurrentContext()?.strokePath()
        
        // Set the bracket line Antialiasing off
        UIGraphicsGetCurrentContext()?.setAllowsAntialiasing(false)
        
        // Set the image based on the contents of the current bitmap-based graphics context to be the scanningRegionView's image
        scanningRegionView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        // Remove the current bitmap-based graphics context from the top of the stack
        UIGraphicsEndImageContext()
        
        // Add the newly created scanningRegionView as a subview of the current view
        view.addSubview(scanningRegionView)
    }
    
    /*
     ----------------------------------------
     MARK: - Construct Scanning Complete View
     ----------------------------------------
     */
    func constructScanningCompleteView() {
        
        // Create an image view object to show the entire view frame as the scanning complete view
        scanningCompleteView = UIImageView(frame: view.frame)
        
        // Create a bitmap-based graphics context as big as the view frame size and make it the Current Context
        UIGraphicsBeginImageContext(scanningCompleteView.frame.size)
        
        // Draw the entire image in the specified rectangle, which is the entire view frame
        scanningCompleteView.image?.draw(in: CGRect(x: 0, y: 0, width: scanningCompleteView.frame.width, height: scanningCompleteView.frame.height))
        
        //-------------------------------------------
        //         Draw the Left Bracket
        //-------------------------------------------
        
        UIGraphicsGetCurrentContext()?.move(to: CGPoint(x:  viewWidth * 0.20, y: viewHeight * 0.5 - edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:  viewWidth * 0.15, y: viewHeight * 0.5 - edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:   viewWidth * 0.15, y: viewHeight * 0.5 + edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:   viewWidth * 0.20, y: viewHeight * 0.5 + edge / 2))
        
        //-------------------------------------------
        //         Draw the Right Bracket
        //-------------------------------------------
        
        UIGraphicsGetCurrentContext()?.move(to: CGPoint(x:  viewWidth * 0.8, y: viewHeight * 0.5 - edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:  viewWidth * 0.85, y: viewHeight * 0.5 - edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:   viewWidth * 0.85, y: viewHeight * 0.5 + edge / 2))
        UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x:   viewWidth * 0.8, y: viewHeight * 0.5 + edge / 2))
        
        //-------------------------------------------
        //    Set Properties of the Bracket Lines
        //-------------------------------------------
        
        UIGraphicsGetCurrentContext()?.setLineCap(CGLineCap.butt)
        UIGraphicsGetCurrentContext()?.setLineWidth(5)
        UIGraphicsGetCurrentContext()?.setStrokeColor(UIColor.green.cgColor)
        UIGraphicsGetCurrentContext()?.setBlendMode(CGBlendMode.normal)
        UIGraphicsGetCurrentContext()?.strokePath()
        UIGraphicsGetCurrentContext()?.setAllowsAntialiasing(false)
        
        // Set the image based on the contents of the current bitmap-based graphics context to be the scanningCompleteView's image
        scanningCompleteView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        // Remove the current bitmap-based graphics context from the top of the stack
        UIGraphicsEndImageContext()
        
        // Add the newly created scanningCompleteView as a subview of the current view
        view.addSubview(scanningCompleteView)
        
        // Move the scanningCompleteView subview so that it appears behind its siblings
        view.sendSubview(toBack: scanningCompleteView)
    }
    
    /*
     --------------------------------------------------------------
     MARK: - AVCaptureMetadataOutputObjectsDelegate Protocol Method
     --------------------------------------------------------------
     */
    
    // Informs the delegate (self) that the capture output object emitted new metadata objects, i.e., a known barcode is read
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Create an Array of acceptable barcode types
        let barcodeTypes = [
            AVMetadataObject.ObjectType.qr
        ]
        
        for metadata in metadataObjects {
            for barcodeType in barcodeTypes {
                if (metadata as AnyObject).type == barcodeType {
                    
                    // Move the scanningCompleteView subview so that it appears on top of its siblings
                    self.view.bringSubview(toFront: scanningCompleteView)
                    
                    // Obtain the QR code as a String.
                    qrCodeRead = (metadata as! AVMetadataMachineReadableCodeObject).stringValue!
                    
                    // Stop the AV Capture Session running
                    self.avCaptureSession.stopRunning()
                    
                    break
                } else {
                    print("Unrecognized Barcode!")
                    return
                }
            }
        }
        
        // If the QR code is read, segue to Quick Response view
        if qrCodeRead != "" {
            prepareData()
        }
    }
    
    /*
     -------------------------
     MARK: - Prepare QR Data
     -------------------------
     */
    func prepareData() {
        let data = qrCodeRead.data(using: .utf8)
        var spotNum = 0
        do{
            /*
             JSONSerialization class is used to convert JSON and Foundation objects (e.g., NSDictionary) into each other.
             JSONSerialization class method jsonObject returns an NSDictionary object from the given JSON data.
             */
            let jsonDataDictionary = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
            
            // Typecast the returned NSDictionary as Dictionary<String, AnyObject>
            let dictionaryOfJsonData = jsonDataDictionary as! Dictionary<String, AnyObject>
            dataObjectToPass["availability"] = dictionaryOfJsonData["availability"]
            dataObjectToPass["card"] = dictionaryOfJsonData["card"]
            dataObjectToPass["cash"] = dictionaryOfJsonData["cash"]
            dataObjectToPass["coin"] = dictionaryOfJsonData["coin"]
            dataObjectToPass["electricVehicle"] = dictionaryOfJsonData["electricVehicle"]
            dataObjectToPass["hasSecurity"] = dictionaryOfJsonData["hasSecurity"]
            dataObjectToPass["latitude"] = dictionaryOfJsonData["latitude"]
            dataObjectToPass["longitude"] = dictionaryOfJsonData["longitude"]
            dataObjectToPass["payPal"] = dictionaryOfJsonData["payPal"]
            dataObjectToPass["spotType"] = dictionaryOfJsonData["spotType"]
            dataObjectToPass["timeLimit"] = dictionaryOfJsonData["timeLimit"]
            dataObjectToPass["cost"] = dictionaryOfJsonData["cost"]
            dataObjectToPass["qr"] = 1

            spotNum = dictionaryOfJsonData["spotNum"] as! Int
        } catch let error as NSError {
            print(error)
        }
        
        //use city and spotNum to get the image
        // Get a reference to the storage service using the default Firebase App
        let storage = Storage.storage()
        // Create a storage reference from our storage service
        let storageRef = storage.reference()
        // Create a reference to the file you want to download
        let imageRef = storageRef.child("images/\(currentCity.city)/\(spotNum).JPG")
        
        // Download in memory with a maximum allowed size of 30MB (30 * 1024 * 1024 bytes)
        imageRef.getData(maxSize: 30 * 1024 * 1024) { data, error in
            if error != nil {
                // Uh-oh, an error occurred!
            } else {
                // Data for image is returned
                let image = UIImage(data: data!)
                self.dataObjectToPass["image"] = image
            }
            self.performSegue(withIdentifier: "Confirm Spot", sender: self)
        }
    }
    
    /*
     -------------------------
     MARK: - Prepare for Segue
     -------------------------
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "Confirm Spot" {
            
            //pass the qrdata downstream to confirm
            // Obtain the object reference of the destination (downstream) view controller
            let confirmAddViewController: ConfirmAddViewController = segue.destination as! ConfirmAddViewController
            
            confirmAddViewController.dataObjectPassed = dataObjectToPass
        }
    }

}
