//
//  LoginScreenViewController.swift
//  Goe
//
//  Created by Kadhir M on 1/15/16.
//  Copyright © 2016 Goe. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import Darwin

class LoginScreenViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    //MARK: IBOutlets
    
    /** The activity indicator for checking userID/pass. */
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    /** Area where FB login button goes. */
    @IBOutlet weak var FacebookView: UIView!
    /** Terms and service button. */
    @IBOutlet weak var termsAndService: UIButton!
    /** Errors loggin in. */
    @IBOutlet weak var errors: UILabel!
    /** Title. */
    @IBOutlet weak var explore: UILabel!
    /** Fetching phone indicator. */
    @IBOutlet weak var fetchingPhoneLocation: UILabel!
    
    //MARK: Login function specific variables
    
    /** Facebook SDK login button.*/
    private let loginView : FBSDKLoginButton = FBSDKLoginButton()
    /** All user details packaged into one string array.*/
    private var userDetailsGlobal: [String]?
    /** User profile picture from Facebook.*/
    private var userGlobalPicture: UIImage?
    /** Has the user agreed to the terms and service.*/
    private var agreedToTerms = false
    /** Holder variable for appTitleHidden. */
    private var appTitleBlank = false
    /** Blank out title if errors variable. */
    private var appTitleHidden: Bool {
        get {
            return appTitleBlank
        } set {
            appTitleBlank = newValue
            if appTitleBlank {
                explore.alpha = 0
            } else {
                explore.alpha = 0.55
            }
        }
    }
    /** User's location to check for account creation. */
    private var userLocation: CLLocation?
    /** Berkeley's location to check against. */
    private var berkeleyLocation: CLLocation?
    /** Valid location for the user. */
    private var validLocation = false
    /** Meters to miles converter. */
    let METERS_TO_MILES = 0.000621371
    /** View did load. */
    private var user_logged_out = false
    
    //MARK: Goe utility helpers
    
    /** Accesses internal core data structures. */
    let goeCoreData = GoeCoreData()
    /** Acess internal cloud kit helper. */
    let goeCloudKit = GoeCloudKit()
    /** Goe core location accesser. */
    let goeCoreLocation = GoeCoreLocationHelper()
    
    //MARK: Methods begin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appTitleHidden = false
        let titleText = NSAttributedString(string: "    Facebook Login")
        loginView.setAttributedTitle(titleText, forState: UIControlState.Normal)
        loginView.readPermissions = ["public_profile", "email", "user_friends"]
        loginView.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(checkForiCloud), name: "goeBecameActive", object: nil)
        startGettingLocations()
    }
    
    /** Starts fetching all the locations needed to see where the user. */
    func startGettingLocations() {
        goeCoreLocation.returnUserLocation(checkUserLocation)
        goeCoreLocation.returnLocation("2739 Channing Way, Berkeley, CA", completionHandler: getBerkeleyLocation)
    }
    
    /** Sets the user's location. */
    func checkUserLocation(location: CLLocation?) {
        if location == nil {
            goeCoreLocation.locationManager.startUpdatingLocation()
            goeCoreLocation.returnUserLocation(checkUserLocation)
        } else {
            userLocation = location
            checkLocation()
        }
    }
    
    /** Sets berkeley's CLLocation. */
    func getBerkeleyLocation(location: CLLocation?) {
        if location == nil {
            goeCoreLocation.returnLocation("2739 Channing Way, Berkeley, CA", completionHandler: getBerkeleyLocation)
        } else {
            berkeleyLocation = location
            checkLocation()
        }
    }
    
    /** Given the user's location and Berkeley's, will either disable the accept terms and conditions button or enable it. */
    func checkLocation() {
        dispatch_async(dispatch_get_main_queue()) {
            if (self.userLocation != nil && self.berkeleyLocation != nil) {
                self.fetchingPhoneLocation.text = ""
                let distance = self.berkeleyLocation!.distanceFromLocation(self.userLocation!) * self.METERS_TO_MILES
                if distance <= 25 {
                    self.checkForiCloud()
                } else {
                    let confirmingRequest = UIAlertController(title: "Location Error", message: "Goe is available only for Cal students and can only be logged in from Berkeley.", preferredStyle: UIAlertControllerStyle.Alert)
                    confirmingRequest.addAction(UIAlertAction(title: "Got It", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(confirmingRequest, animated: true, completion: nil)
                }
            }
        }
    }
    
    //MARK: View Did Appear
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if (user_logged_out) {
            startGettingLocations()
        }
    }
    
    /** Checks to make sure iCloud drive is enabled on the users phone. Without iCloud drive, the server will not think the user is authenticated. */
    func checkForiCloud() {
        if NSFileManager.defaultManager().ubiquityIdentityToken == nil {
            termsAndService.enabled = false
            termsAndService.hidden = true
            let doubleChecking = UIAlertController(title: "iCloud Drive Not Enabled", message: "Looks like your iCloud Drive isn't enabled. Go to settings and enable it now?", preferredStyle: UIAlertControllerStyle.Alert)
            doubleChecking.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Destructive, handler: nil))
            doubleChecking.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { action in
                let url = NSURL(string: "prefs:root=CASTLE")
                UIApplication.sharedApplication().openURL(url!)
            }))
            self.presentViewController(doubleChecking, animated: true, completion: nil)
        } else {
            if self.termsAndService.enabled != true {
                self.appTitleHidden = false
                self.termsAndService.alpha = 0
                self.termsAndService.enabled = true
                self.termsAndService.hidden = false
                self.errors.text = ""
                UIView.transitionWithView(self.termsAndService, duration: 0.35, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.termsAndService.alpha = 1
                    }, completion: nil)
            }
        }
    }
    
    /** Hooked up to the agree to terms and service button. Once the user agrees, this will present the login button. */
    @IBAction func agreeToTerms(sender: UIButton) {
        if agreedToTerms == false {
            loginView.frame = CGRect(x: 0, y: 0, width: loginView.frame.size.width, height: loginView.frame.size.height*1.25)
            loginView.center = FacebookView.center
            self.view.addSubview(loginView)
            loginView.alpha = 0
            UIView.transitionWithView(loginView, duration: 0.75, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
                self.loginView.alpha = 1
                self.termsAndService.setTitle("I agree to terms and service", forState: UIControlState.Normal)
                self.termsAndService.backgroundColor = UIColorFromHex(0x008040)
                self.termsAndService.alpha = 0.5
                }, completion: nil)
            agreedToTerms = true
        }
    }
    
    //MARK: Facebook Delegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if ((error) == nil) {
            activityIndicator.startAnimating()
            returnUserData(callGoeCloudKit)
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) { }
    
    //MARK: User account methods
    
    /** Once authenticated via Facebook, returns the user details and profile image to create a user account. */
    func returnUserData(completionHandler: ([String], UIImage) -> Void) {
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, picture.type(large), email"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            if ((error) == nil) {
                let userID : NSString = result.valueForKey("id") as! NSString
                let userName : NSString = result.valueForKey("name") as! NSString
                let userEmail : NSString? = result.valueForKey("email") as? NSString
                var image: UIImage?
                let url = NSURL(string: "https://graph.facebook.com/\(userID)/picture?type=large")
                let urlRequest = NSURLRequest(URL: url!)
                let session = NSURLSession.sharedSession()
                let task = session.dataTaskWithRequest(urlRequest, completionHandler: { data, response, error -> Void in
                    image = UIImage(data: data!)
                    let userEmail = userEmail as? String
                    completionHandler([userName as String, userID as String, userEmail ?? ""], image ?? UIImage(named: "ID Card-50")!)
                })
                task.resume()
            }
        })
    }
    
    /** Calls on fetchUser in goeCloudKit to see if the Facebook User exists. */
    func callGoeCloudKit(userDetails: [String], userProfile: UIImage) {
        self.userDetailsGlobal = userDetails
        self.userGlobalPicture = userProfile
        goeCloudKit.fetchUser(userDetailsGlobal![1], completionHandler: createAccountOrLogin)
    }
    
    /** Will figure out whether or not an account exists that is associated with the Facebook user and executes a method accordingly. */
    func createAccountOrLogin(accountRecord: CKRecord?) {
        if accountRecord != nil {
            successfulLogin(accountRecord!)
        } else {
            self.goeCloudKit.createUser(userDetailsGlobal![0], userID: userDetailsGlobal![1], profilePicture: userGlobalPicture!, emailAddress: userDetailsGlobal![2] ?? "None", facebookUser: true, completionHandler: segueOrThrowError)
        }
    }
    
    /** If the Facebook user has an account, will proceed to log the user into Goe. */
    func successfulLogin(record: CKRecord?){
        if (record!["Status"] as? Int) == 666 {
            performSegueWithIdentifier("Blocked", sender: self)
        }
        let userName = record!.valueForKey("Name") as? String
        let userID = record!.valueForKey("ID") as? String
        let profilePicture = goeCloudKit.getProfilePhoto(record!)
        let userReference = record!.recordID.recordName
        setLoggedInUser(userName!, userID: userID!, profilePicture: profilePicture, userReference: userReference)
        activityIndicator.stopAnimating()
        performSegueWithIdentifier("Login", sender: self)
    }
    
    /** Sets the current logged in user. */
    func setLoggedInUser(userName: String, userID: String, profilePicture: NSData?, userReference: String) {
        goeCoreData.deleteAllData("User")
        dispatch_async(dispatch_get_main_queue(), {
            self.goeCoreData.createUser(userName, userID: userID, profilePicture: profilePicture, userReference: userReference)
        })
    }
    
    //MARK: Seguing Methods
    
    /** Keeps track of the total responses from the server. */
    var totalResponses = 0
    
    /** Once the server has communicated that it has properly stored all the needed information, it will wait 2 seconds just to be sure that no errors will occur, then will log the new user into Goe. */
    func segueOrThrowError(error: NSError?) {
        if error == nil {
            dispatch_async(dispatch_get_main_queue(), {
                self.totalResponses += 1
                if self.totalResponses == 2 {
                    sleep(2)
                    self.activityIndicator.stopAnimating()
                    self.totalResponses = 0
                    self.performSegueWithIdentifier("Login", sender: self)
                }
            })
        } else {
            appTitleHidden = true
            errors.text = "There was an error creating your account. Please make sure you have iCloudDrive enabled (Settings -> iCloud). If it is enabled, contact support."
        }
    }
    
    //MARK: Privacy and Terms and Service
    
    /** Link to the privacy policy. */
    @IBAction func privacyPolicy(sender: UIButton) {
        if let url = NSURL(string: "https://docs.google.com/document/d/1MCF4EkmaRwfV9QW3ZgjLo6YC4onSxmHscbG_yME99IU/edit") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    /** Link to the terms and service. */
    @IBAction func hyperLink(sender: UIButton) {
        if let url = NSURL(string: "https://docs.google.com/document/d/1nf4yIxkAK2okiw-z3DN7JCwqQOE3NSfpM4Qyxe_mu70/edit") {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
}
