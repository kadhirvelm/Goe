//
//  Utilities.swift
//  Goe
//
//  Created by Kadhir M on 8/8/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

class GoeUtilities: AppDelegate{
    
    /** Associated scrollView with this utilities function. */
    var scrollView: UIScrollView?
    /** Associated viewController with this utilities function. */
    var viewController: UIViewController?
    /** Associated navigationController with this utilities function. */
    var navigationController: UINavigationController?
    /** Public database accesser. */
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    /** Viewcontroller to segue to. */
    var segueViewController: UIViewController?
    /** Errors that can be thrown. */
    enum UtilitiesError: ErrorType {
        case NavigationControllerEmpty
        case ViewControllerEmpty
        case ScrollViewEmpty
    }
    
    //MARK: Other Utility Methods
    let goeCoreData = GoeCoreData()
    
    override init() {}
    
    init(viewController: UIViewController?, navigationController: UINavigationController?, scrollView: UIScrollView?) {
        self.viewController = viewController
        self.navigationController = navigationController
        self.scrollView = scrollView
    }
    
    /** Goes through and force reloads the profile view controller. */
    func segueAndForceReloadProfileViewController() {
        do {
            guard navigationController != nil else { throw UtilitiesError.NavigationControllerEmpty }
            for viewController in (self.navigationController!.viewControllers) {
                if viewController is ProfileViewController {
                    let destination = viewController as! ProfileViewController
                    destination.forceReload = true
                    self.navigationController!.popToViewController(viewController, animated: true)
                }
            }
        } catch UtilitiesError.NavigationControllerEmpty {
            print("Cannot segue without a valid navigation controller in \(viewController)")
        } catch {
            print("Something else went wrong in segueAndForceReloadProfileViewController...")
        }
    }
    
    /** Sets the keyboard observers. */
    func setKeyboardObservers() {
        do {
            guard scrollView != nil else { throw UtilitiesError.ScrollViewEmpty }
            guard viewController != nil else { throw UtilitiesError.ViewControllerEmpty }
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillDismiss), name: UIKeyboardWillHideNotification, object: nil)
        } catch UtilitiesError.ScrollViewEmpty {
            print("Cannot set keyboard observers on a nil scrollview in Goe Utilities for \(self.viewController)")
        } catch UtilitiesError.ViewControllerEmpty{
            print("Cannot set keyboard observers on a nil viewController in Goe Utilities in \(self)")
        } catch {
            print("Something else went wrong in setKeyboardObservers...")
        }
    }
    
    /** If the keyboard will show, raises the view up accordingly. */
    @objc func keyboardWillShow(notification: NSNotification) {
        let userInfo: NSDictionary = notification.userInfo!
        let keyboardSize = userInfo.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        let contentInsets = UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)
        dispatch_async(dispatch_get_main_queue()) {
            self.scrollView!.contentInset = contentInsets
            self.scrollView!.scrollIndicatorInsets = contentInsets
        }
    }
    
    /** If the keyboard will dismiss, lowers the view up accordingly. */
    @objc func keyboardWillDismiss(notification: NSNotification) {
        self.scrollView!.contentInset = UIEdgeInsetsZero
        self.scrollView!.scrollIndicatorInsets = UIEdgeInsetsZero
    }
    
    /** Prints out all the subscriptions the user is subscribed to. */
    func printAllSubscriptions() {
        publicDatabase.fetchAllSubscriptionsWithCompletionHandler { (subscriptions, error) in
            print(subscriptions)
        }
    }
    
    /** Slides to the top of the scrollview. */
    func slideToExtreme(toTop: Bool = true) {
        do {
            guard scrollView != nil else { throw UtilitiesError.ScrollViewEmpty }
            if toTop {
                scrollView?.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            } else {
                let bottom = scrollView?.contentSize.height
                scrollView?.setContentOffset(CGPoint(x: 0, y: bottom!), animated: true)
            }
        } catch UtilitiesError.ScrollViewEmpty {
            print("Cannot scroll to top when scrollview is not specified in \(self.viewController)")
        } catch {
            print("Something else went wrong when scrolling to the top of the scrollview")
        }
    }
    
    /** Logs the user out and instantiates the main view controller. */
    func logout(viewController: UIViewController) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            self.goeCoreData.deleteAllData("User")
            self.clearCache()
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil);
        let LoginScreenViewController = storyboard.instantiateViewControllerWithIdentifier("LoginScreenViewController") as UIViewController;
        dispatch_async(dispatch_get_main_queue()) {
            viewController.presentViewController(LoginScreenViewController, animated: true) {}
        }
    }
    
    /** Given the user name, will split based on the period and return the name. */
    func splitUserName(username: String, returnname: String? = nil) -> String {
        let tempTitle = username.characters.split{$0 == "."}.map(String.init)
        if returnname == "Last" {
            return tempTitle[1]
        } else if returnname == "First" {
            return tempTitle[0]
        } else if returnname == "Last Initial"{
            return "\(tempTitle[0]) \((tempTitle[1].characters.first)!)."
        } else {
            return "\(tempTitle[0]) \(tempTitle[1])"
        }
    }
    
    /** Adjusts the background scrollview to exactly fit what's inside.*/
    func setBackgroundSize(padding: CGFloat? = nil){
        do {
            guard scrollView != nil else { throw UtilitiesError.ScrollViewEmpty }
            guard viewController != nil else { throw UtilitiesError.ViewControllerEmpty }
            dispatch_async(dispatch_get_main_queue()) {
                var contentRect = CGRectZero
                for view in self.scrollView!.subviews {
                    if view.hidden == false {
                        contentRect = CGRectUnion(contentRect, view.frame)
                    }
                }
                var final_height = contentRect.height
                if padding != nil {
                    final_height += padding!
                }
                UIView.animateWithDuration(0.5, animations: {
                    self.scrollView!.contentSize = CGSize(width: self.viewController!.view.frame.width, height: final_height)
                    self.scrollView?.layoutIfNeeded()
                })
            }
        } catch UtilitiesError.ScrollViewEmpty {
            print("Scrollview cannot be nil when setting the background size.")
        } catch UtilitiesError.ViewControllerEmpty {
            print("Viewcontroller cannot be nil when setting the background size.")
        } catch {
            print("Something else went wrong when setting the background size. ")
        }
    }
    
    func setScrollViewBackgroundSize(ignoreImageViews: Bool = false, padding: CGFloat? = nil) {
        do {
            guard scrollView != nil else { throw UtilitiesError.ScrollViewEmpty }
            guard viewController != nil else { throw UtilitiesError.ViewControllerEmpty }
                var maxY = CGFloat(0)
                for view in self.scrollView!.subviews {
                    if (view.hidden == false && view.frame.maxY > maxY && !(ignoreImageViews && view is UIImageView)) {
                        maxY = view.frame.maxY
                    }
                }
            if padding != nil {
                maxY += padding!
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.scrollView!.contentSize = CGSize(width: self.viewController!.view.frame.width, height: maxY)
            }
        } catch UtilitiesError.ScrollViewEmpty {
            print("Scrollview cannot be nil when setting the background size.")
        } catch UtilitiesError.ViewControllerEmpty {
            print("Viewcontroller cannot be nil when setting the background size.")
        } catch {
            print("Something else went wrong when setting the background size. ")
        }
    }
    
    /** Adjusts the object's height to fit its contents. */
    func setObjectHeight(object: AnyObject, padding: CGFloat) {
        dispatch_async(dispatch_get_main_queue()) {
            NSLayoutConstraint.deactivateConstraints(object.constraints)
            object.sizeToFit()
            let height = (object.frame.height) + padding
            let newConstraint = NSLayoutConstraint(item: object, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: height)
            NSLayoutConstraint.activateConstraints([newConstraint])
        }
    }
    
    /** Scrolls the uiview to show the text view. */
    func scrollToShowRect(rect: CGRect) {
        do {
            guard scrollView != nil else { throw UtilitiesError.ScrollViewEmpty }
            scrollView?.setContentOffset(rect.origin, animated: true)
        } catch UtilitiesError.ScrollViewEmpty {
            print("Cannot scroll to textview when the scrollview is nil")
        } catch {
            print("Something else went wrong when scrolling to text view.")
        }
    }
    
    /** Returns false is the user's bio is not set. */
    func checkUserBio(userCloudRecord: CKRecord, completionHandler: (() -> ())? = nil) {
        let userDetails = userCloudRecord.valueForKey("Details") as? [String]
        if ((userDetails![0] == "Welcome to Goe. Edit your bio with the settings button in the top right.") || (userDetails![0].characters.count == 0)) {
            dispatch_async(dispatch_get_main_queue(), {
                let confirmingRequest = UIAlertController(title: "Please Set Your Bio", message: "This is to let hosts know how cool you are. Don't forget to save!", preferredStyle: UIAlertControllerStyle.Alert)
                if completionHandler == nil {
                    confirmingRequest.addAction(UIAlertAction(title: "Go To Profile", style: UIAlertActionStyle.Default, handler: { action in self.segueToEditBio() }))
                } else {
                    confirmingRequest.addAction(UIAlertAction(title: "Go To Profile", style: UIAlertActionStyle.Default, handler: { action in completionHandler!() }))
                }
                self.viewController!.presentViewController(confirmingRequest, animated: true, completion: nil)
            })
        }
    }
    
    /** Segues to the profile view controller, first setting forceSetBio to be true. */
    func segueToEditBio() {
        do {
            guard navigationController != nil else { throw UtilitiesError.NavigationControllerEmpty }
            let tabBar = self.navigationController?.tabBarController
            for navigation in (tabBar?.viewControllers)! {
                if navigation.title == "Profile" {
                    for viewController in navigation.childViewControllers {
                        if let destination = viewController as? ProfileViewController {
                            dispatch_async(dispatch_get_main_queue(), {
                                destination.forceSetBio = true
                                tabBar?.selectedIndex = 0
                            })
                        }
                    }
                }
            }
        } catch UtilitiesError.NavigationControllerEmpty {
            print("Cannot segue without a valid navigation controller in \(viewController)")
        } catch {
            print("Something else went wrong in segueAndForceReloadProfileViewController...")
        }
    }
}

extension UIView {
    func rotate360Degrees(duration: CFTimeInterval = 1.0, completionDelegate: CAAnimationDelegate? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(M_PI * 2.0)
        rotateAnimation.duration = duration
        
        if completionDelegate != nil {
            rotateAnimation.delegate = completionDelegate
        }
        self.layer.addAnimation(rotateAnimation, forKey: nil)
    }
}

protocol GoeMapContainerDelegate {
    /** Handles when the destination needs to be placed on the map. */
    func mapDestination(title: String, coordinates: CLLocation?, textEntryEnabled: Bool)
    /** Handles when the rendezvous needs to be placed on the map. */
    func mapRendezvous(title: String, coordinates: CLLocation?, textEntryEnabled: Bool)
    /** Enables the editing of both destination and rendezvous. */
    func enableEditing(enable: Bool)
}
