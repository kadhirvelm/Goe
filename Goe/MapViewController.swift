//
//  MapViewController.swift
//  Goe
//
//  Created by Kadhir M on 8/16/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit
import MapKit

protocol GoeMapViewDelegate {
    /** Handles when the destination is recorded. */
    func destinationResponse(title: String, address: String, coordinates: CLLocation)
    /** Handles when the rendezvous is recorded. */
    func rendezvousResponse(title: String, address: String, coordinates: CLLocation)
    /** Optional method: Sends a respose to when one of the textviews begins editing. */
    func goeMapTextViewDidBeginEditing(textView: UITextView)
    /** Optional method: Sends a respose to when one of the textviews ends editing. */
    func goeMapTextViewDidEndEditing(textView: UITextView)
}

extension GoeMapViewDelegate {
    func goeMapTextViewDidBeginEditing(textView: UITextView) {}
    func goeMapTextViewDidEndEditing(textView: UITextView) {}
}

class MapViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, MKMapViewDelegate, MKLocalSearchCompleterDelegate, GoeMapContainerDelegate{

    //MARK: IBOutlets
    
    /** The mapview presented. */
    @IBOutlet weak var goeMapView: MKMapView!
    /** Destination addresses table view. */
    @IBOutlet weak var destinationTableView: UITableView!
    /** Rendezvous addresses table view. */
    @IBOutlet weak var rendezvousTableView: UITableView!
    /** Destination text view. */
    @IBOutlet weak var destinationTextView: UITextView!
    /** Rendezvous text view. */
    @IBOutlet weak var rendezvousTextView: UITextView!

    //MARK: Utiltiy Helpers
    
    /** Goe core location helper. */
    var goeLocation: GoeCoreLocationHelper?
    /** Users current location. */
    var currentLocation: CLLocationCoordinate2D?
    /** Delegate setter. */
    var delegate: GoeMapViewDelegate?
    /** Utilities helper. */
    var goeUtilities: GoeUtilities?
    
    //MARK: Autocomplete Items
    
    /** Destination search completer. */
    var destinationCompleter = MKLocalSearchCompleter()
    /** Rendezvous search completer. */
    var rendezvousCompleter = MKLocalSearchCompleter()
    /** Destination search results. */
    var destinationSearchResults = [MKLocalSearchCompletion]()
    /** Rendezvous search results. */
    var rendezvousSearchResults = [MKLocalSearchCompletion]()
    /** Final destination result. */
    var destination: MKLocalSearchCompletion?
    /** Final Rendezvous result. */
    var rendezvous: MKLocalSearchCompletion?
    /** Destination pin. */
    var destinationPin: GoeAdventureLocation?
    /** Rendezvous pin. */
    var rendezvousPin: GoeAdventureLocation?
    
    //MARK: Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setAllDelegates()
        goeLocation!.returnUserLocation(setMapItems)
    }
    
    /** Set all the child view delegate methods. */
    func setAllDelegates() {
        goeLocation = GoeCoreLocationHelper()
        goeMapView.delegate = self
        
        destinationTableView.dataSource = self
        destinationTableView.delegate = self
        rendezvousTableView.dataSource = self
        rendezvousTableView.delegate = self
        
        destinationTextView.delegate = self
        rendezvousTextView.delegate = self
        
        destinationCompleter.delegate = self
        destinationCompleter.filterType = MKSearchCompletionFilterType.LocationsOnly
        rendezvousCompleter.delegate = self
        rendezvousCompleter.filterType = MKSearchCompletionFilterType.LocationsOnly
    }
    
    /** Zooms the map into the user's current location. */
    func setMapItems(currentLocation: CLLocationCoordinate2D?) {
        if (destinationPin == nil && rendezvousPin == nil) {
            if currentLocation != nil {
                self.currentLocation = currentLocation
                let regionRadius = CLLocationDistance(1000)
                let region = MKCoordinateRegionMakeWithDistance(currentLocation!, regionRadius * 2, regionRadius * 2)
                goeMapView.setRegion(region, animated: true)
                destinationCompleter.region = region
                rendezvousCompleter.region = region
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.destinationTextView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
        self.rendezvousTextView.addObserver(self, forKeyPath: "contentSize", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        goeLocation = nil
        if destinationTextView != nil {
            destinationTextView.removeObserver(self, forKeyPath: "contentSize")
        }
        if rendezvousTextView != nil {
            rendezvousTextView.removeObserver(self, forKeyPath: "contentSize")
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let textView = object as! UITextView
        var topCorrect = (textView.bounds.size.height - textView.contentSize.height * textView.zoomScale) / 2
        topCorrect = topCorrect < 0.0 ? 0.0 : topCorrect;
        textView.contentInset.top = topCorrect
    }
    
    //MARK: GoeMapContainer Delegate
    
    func mapDestination(title: String, coordinates: CLLocation?, textEntryEnabled: Bool) {
        if coordinates != nil {
            do {
                destinationPin = try GoeAdventureLocation(title: title, destination_rendezvous: "Destination", coordinate: coordinates!.coordinate)
                goeMapView.addAnnotation(destinationPin!)
                goeMapView.showAnnotations(goeMapView.annotations, animated: true)
            } catch {
                print("Error setting map destination pin")
            }
        }
        destinationTextView.editable = textEntryEnabled
        UIView.transitionWithView(destinationTextView, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.destinationTextView.text = title
            }, completion: nil)
    }
    
    func mapRendezvous(title: String,coordinates: CLLocation?, textEntryEnabled: Bool) {
        if coordinates != nil {
            do {
                rendezvousPin = try GoeAdventureLocation(title: title, destination_rendezvous: "Rendezvous", coordinate: coordinates!.coordinate)
                goeMapView.addAnnotation(rendezvousPin!)
                goeMapView.showAnnotations(goeMapView.annotations, animated: true)
            } catch {
                print("Error setting map destination pin")
            }
        }
        rendezvousTextView.editable = textEntryEnabled
        UIView.transitionWithView(rendezvousTextView, duration: 0.5, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            self.rendezvousTextView.text = title
            }, completion: nil)
    }
    
    func enableEditing(enable: Bool) {
        destinationTextView.editable = enable
        rendezvousTextView.editable = enable
        if enable == false {
            destinationTableView.hidden = true
            rendezvousTableView.hidden = true
        }
    }
    
    //MARK: Textview Delegate Methods
    
    func textViewDidBeginEditing(textView: UITextView) {
        textView.scrollEnabled = false
        textView.showsVerticalScrollIndicator = false
        self.delegate?.goeMapTextViewDidBeginEditing(textView)
        adjustTextAndTables(textView)
        switch textView {
        case destinationTextView:
            if textView.text == "Address of Destination" {
                textView.text = ""
            }
        case rendezvousTextView:
            if textView.text == "Address of Rendezvous" {
                textView.text = ""
            }
        default:
            break
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        textView.scrollEnabled = true
        textView.showsVerticalScrollIndicator = true
        textView.textColor = UIColor.blackColor()
        whichTableViewResults(nil, textView: textView).1!.queryFragment = textView.text
        
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    /** Given either the textView or the tableView, will either hide or show the associated tableview. */
    func adjustTextAndTables(textView: UITextView? = nil, tableView: UITableView? = nil, resignFirst: Bool = false) {
        var finalTextView: UITextView?
        if textView == nil {
            switch tableView! {
            case destinationTableView:
                finalTextView = destinationTextView
            case rendezvousTableView:
                finalTextView = rendezvousTextView
            default:
                break
            }
        } else {
            finalTextView = textView
        }
        
        switch finalTextView! {
        case destinationTextView:
            if resignFirst {
                destinationTextView!.resignFirstResponder()
            } else {
                destinationTableView.hidden = !destinationTableView.hidden
            }
        case rendezvousTextView:
            if resignFirst {
                rendezvousTextView!.resignFirstResponder()
            } else {
                rendezvousTableView.hidden = !rendezvousTableView.hidden
            }
        default:
            break
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.delegate?.goeMapTextViewDidEndEditing(textView)
        adjustTextAndTables(textView)
    }
    
    //MARK: Tableview Delegate Methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (whichTableViewResults(tableView, textView: nil).0!.count)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let searchResult = whichTableViewResults(tableView, textView: nil).0![indexPath.row]
        let cell = UITableViewCell(style: .Subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let results = whichTableViewResults(tableView, textView: nil).0![indexPath.row]
        adjustTextAndTables(tableView: tableView, resignFirst: true)
        switch tableView {
        case destinationTableView:
            destinationTextView.text = results.title
            destination = results
            goeLocation?.returnLocation(results.subtitle, completionHandler: handleDestinationDelegate)
        case rendezvousTableView:
            rendezvousTextView.text = results.title
            rendezvous = results
            goeLocation?.returnLocation(results.subtitle, completionHandler: handleRendezvousDelegate)
        default:
            break
        }
    }
    
    /** Handles the destination completion, then goes to the general delegate. */
    func handleDestinationDelegate(coordinates: CLLocation?) {
        if (coordinates != nil && delegate != nil) {
            self.delegate?.destinationResponse(destination!.title, address: destination!.subtitle, coordinates: coordinates!)
            handleGeneralDelegate(coordinates, pin: destinationPin, whichType: "Destination")
        }
    }
    
    /** Handles the rendezvous completion. */
    func handleRendezvousDelegate(coordinates: CLLocation?) {
        if (coordinates != nil && delegate != nil) {
            self.delegate?.rendezvousResponse(rendezvous!.title, address: rendezvous!.subtitle, coordinates: coordinates!)
            handleGeneralDelegate(coordinates, pin: rendezvousPin, whichType: "Rendezvous")
        }
    }
    
    /** Handles placing the annotations on the mapkit. */
    func handleGeneralDelegate(coordinates: CLLocation?, pin: GoeAdventureLocation?, whichType: String) {
        if coordinates?.coordinate != nil {
            do {
                if pin != nil {
                    goeMapView.removeAnnotation(pin!)
                }
                switch whichType {
                case "Destination":
                    destinationPin = try GoeAdventureLocation(title: destination!.title, destination_rendezvous: whichType, coordinate: (coordinates?.coordinate)!)
                    goeMapView.addAnnotation(destinationPin!)
                case "Rendezvous":
                    rendezvousPin = try GoeAdventureLocation(title: rendezvous!.title, destination_rendezvous: whichType, coordinate: (coordinates?.coordinate)!)
                    goeMapView.addAnnotation(rendezvousPin!)
                default:
                    print("Erroring in handling general delegate")
                }
                goeMapView.showAnnotations(goeMapView.annotations, animated: true)
                
            } catch {
                print("Errors thrown when setting destination pin")
            }
        }
    }
    
    /** Returns the appropriate tableview's results. */
    func whichTableViewResults(tableView: UITableView?, textView: UITextView?) -> ([MKLocalSearchCompletion]?, MKLocalSearchCompleter?) {
        if tableView != nil {
            switch tableView! {
            case destinationTableView:
                return (destinationSearchResults, destinationCompleter)
            case rendezvousTableView:
                return (rendezvousSearchResults, rendezvousCompleter)
            default:
                return (nil, nil)
            }
        } else {
            switch textView! {
            case destinationTextView:
                return (destinationSearchResults, destinationCompleter)
            case rendezvousTextView:
                return (rendezvousSearchResults, rendezvousCompleter)
            default:
                return (nil, nil)
            }
        }
    }
    
    //MARK: Mapview Delegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var finalView: MKPinAnnotationView
        if let annotation = annotation as? GoeAdventureLocation {
            let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            if annotation.destination_rendezvous == "Rendezvous" {
                pin.pinTintColor = UIColor.blueColor()
            }
            finalView = pin
            finalView.canShowCallout = true
            finalView.calloutOffset = CGPoint(x: -5, y: -5)
            return finalView
        }
        return nil
    }
    
    //MARK: Search Completion Delegate
    
    func completerDidUpdateResults(completer: MKLocalSearchCompleter) {
        switch completer {
        case destinationCompleter:
            destinationSearchResults = completer.results
            destinationTableView.reloadData()
        case rendezvousCompleter:
            rendezvousSearchResults = completer.results
            rendezvousTableView.reloadData()
        default:
            print("Erroring out when completing")
            break
        }
    }
    
    func completer(completer: MKLocalSearchCompleter, didFailWithError error: NSError) {
        print("Error fetching: \(error)")
    }
}
