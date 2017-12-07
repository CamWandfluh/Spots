//
//  MapViewController.swift
//  IOSFinalProject
//
//  Created by Cameron Wandfluh on 11/16/17.
//  Copyright © 2017 Team 4. All rights reserved.
//
import CoreLocation
import UIKit
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var moveToCreatePost: UIButton!
    @IBOutlet weak var moveToProfile: UIBarButtonItem!
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.startUpdatingLocation()
        return manager
    }()
    
    var currLocation : CLLocationCoordinate2D = CLLocationCoordinate2D()
    var regionRadius: CLLocationDistance = 1000
    
    convenience init() {
        self.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setting the initial location to Columbia, MO for testing purposes?
        // want to eventually set the initial location to a radius around the user...
        let initialLocation = CLLocation(latitude: 38.9404, longitude: -92.3277)
        centerMapOnLocation(location: initialLocation)
        
        mapView.delegate = self
        
        // change of font and font color of navigation controller
        self.navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font: UIFont(name: "Gujarati Sangam MN", size: 20)!, NSAttributedStringKey.foregroundColor: UIColor.white]
        
        let manager = self.locationManager
        self.currLocation = CLLocationCoordinate2D()
        manager.requestWhenInUseAuthorization()
        
        // Retrieve records
        let zone = Zone.defaultPublicDatabase()
        zone.retrieveObjects(completionHandler: { (posts: [Post]) in
            for post in posts{
                let dogPost = DogPost(title: post.name, desc: post.description, coordinate: CLLocationCoordinate2D(latitude: post.latitude, longitude: post.longitude), duration: post.duration,photo: (post.photo?.image)!)
                print(post.name)
                print("latitude: " + "\(post.latitude)")
                print("longitude: " + "\(post.longitude)")
                
                self.mapView.addAnnotation(dogPost)
            }
        })
        
        let dogPost = DogPost(title: "Spot", desc: "Our mascot is out and about!", coordinate: CLLocationCoordinate2D(latitude: 38.946547, longitude: -92.328597), duration: 15, photo: UIImage(named: "Dog")!)
        mapView.addAnnotation(dogPost)
        
        setImageIcons()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locationManager.location != nil{
            currLocation = locationManager.location!.coordinate
            print("locations = \(currLocation.latitude) \(currLocation.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if case .authorizedWhenInUse = status{
            manager.requestLocation()
        } else {
            print(status)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let CreatePostViewController = segue.destination as? CreatePostViewController {
            CreatePostViewController.latitude = currLocation.latitude
            CreatePostViewController.longitude = currLocation.longitude
        }
        
        if segue.identifier == "ShowDogPost" {
            if segue.destination is DogPostViewController {
//                DogPostViewController.dogName = post.name
            }
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuthorizationStatus()
    }
    
    let locationManager2 = CLLocationManager()
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            mapView.showsUserLocation = true
        } else {
            locationManager2.requestAlwaysAuthorization()
        }
    }
    
    func setImageIcons() {
        //E77C1E
        let size = moveToCreatePost.frame.size
        let image  = UIImage(named: "Plus")?.resizedImageWithinSquare(rectSize: size)
        moveToCreatePost.setBackgroundImage(image, for: .normal)
        
        let profileButton: UIButton = UIButton(type: UIButtonType.custom)
        profileButton.frame.size = CGSize(width: 30, height: 30)
        //add function for button
        //button.addTarget(self, action: Selector("goToProfile"), for: UIControlEvents.touchUpInside)
        //set frame
        let profileSize = profileButton.frame.size
        let profileImage = UIImage(named: "Profile")?.resizedImageWithinSquare(rectSize: profileSize)
        profileButton.setImage(profileImage, for: .normal)
        
        let barButton = UIBarButtonItem(customView: profileButton)
        //assign button to navigationbar
        self.navigationItem.rightBarButtonItem = barButton
        
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MapViewController: MKMapViewDelegate {
    // gets called for every annotation added to the map to return the view for each annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // in case the map uses other annotations, check if the annotation is of type DogPost...
        // need to change this to use our structure
        guard let annotation = annotation as? DogPost else { return nil }
        // To make markers appear, create each view as an MKMarkerAnnotationView
        let identifier = "marker"
        var view: MKAnnotationView
        // a map view reuses annotation views that are no longer visible. check to see if a reusable annotation view is available before creating a new one.
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            //  create a new MKMarkerAnnotationView object, if an annotation view could not be dequeued. It uses the title and subtitle properties of your Artwork class to determine what to show in the callout.
            view = DogAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            let rightButton: AnyObject! = UIButton(type: UIButtonType.detailDisclosure)
            view.rightCalloutAccessoryView = rightButton as? UIView
//            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        view.image = annotation.photo.resizedImageWithinSquare(rectSize: CGSize(width: 56, height: 56))
        view.image = maskRoundedImage(image: view.image!, radius: 28)
        return view
    }
    
    func maskRoundedImage(image: UIImage, radius: CGFloat) -> UIImage {
        let imageView: UIImageView = UIImageView(image: image)
        let layer = imageView.layer
        layer.masksToBounds = true
        layer.cornerRadius = radius
        layer.borderWidth = 2
        layer.borderColor = UIColor(rgb: 0xE77C1E).cgColor
        UIGraphicsBeginImageContext(imageView.bounds.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return roundedImage!
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl){
        if control == view.rightCalloutAccessoryView {
            performSegue(withIdentifier: "ShowDogPost", sender: self)
        }
    }

}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

extension UIImage {
    /// Returns a image that fills in newSize
    func resizedImage(newSize: CGSize) -> UIImage {
        // Guard newSize is different
        guard self.size != newSize else { return self }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    
    /// Returns a resized image that fits in rectSize, keeping it's aspect ratio
    /// Note that the new image size is not rectSize, but within it.
    func resizedImageWithinRect(rectSize: CGSize) -> UIImage {
        let widthFactor = size.width / rectSize.width
        let heightFactor = size.height / rectSize.height
        
        var resizeFactor = widthFactor
        if size.height > size.width {
            resizeFactor = heightFactor
        }
        
        let newSize = CGSize(width: size.width/resizeFactor, height: size.height/resizeFactor)
        let resized = resizedImage(newSize: newSize)
        return resized
    }
    
    func resizedImageWithinSquare(rectSize: CGSize) -> UIImage {
        let minValue = min(rectSize.height, rectSize.width)
        let size = CGSize(width: minValue, height: minValue)
        
        return self.resizedImage(newSize: size)
    }
}
