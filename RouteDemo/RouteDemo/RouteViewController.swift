//
//  RouteViewController.swift
//  RouteDemo
//
//  Created by Simon Ng on 8/11/2016.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit
import MapKit

class RouteViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView!
    
    private var annotations = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let longpressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(pinLocation))
        longpressGestureRecognizer.minimumPressDuration = 0.3
        mapView.addGestureRecognizer(longpressGestureRecognizer)
        
        mapView.delegate = self
        
        // Do any additional setup after loading the view.
    }

    @objc func pinLocation(sender: UILongPressGestureRecognizer) {
        if sender.state != .ended {
            return
        }
        
        let tappedPoint = sender.location(in: mapView)
        
        let tappedCoordinate = mapView.convert(tappedPoint, toCoordinateFrom: mapView)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = tappedCoordinate
        
        annotations.append(annotation)
        
        mapView.showAnnotations([annotation], animated: false)
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        let annotationView = views[0]
        let endFrame = annotationView.frame
        annotationView.frame = endFrame.offsetBy(dx: 0, dy: -600)
        UIView.animate(withDuration: 0.3, animations: {() -> Void in
            annotationView.frame = endFrame
        })
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 3.0
        renderer.strokeColor = UIColor.purple
        renderer.alpha = 0.5
        
        let visibleMapRect = mapView.mapRectThatFits(renderer.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50))
        mapView.setRegion(MKCoordinateRegion(visibleMapRect), animated: true)
        
        return renderer
    }

    @IBAction func drawPolylines() {
        mapView.removeOverlays(mapView.overlays)
        
        var coordinates = [CLLocationCoordinate2D]()
        for annotation in annotations {
            coordinates.append(annotation.coordinate)
        }
        
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        
        mapView.addOverlay(polyline)
    }
    
    @IBAction func drawRoute() {
        mapView.removeOverlays(mapView.overlays)
        
        var coordinates = [CLLocationCoordinate2D]()
        for annotation in annotations {
            coordinates.append(annotation.coordinate)
        }
        var index = 0
        let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
        let visibleMapRect = mapView.mapRectThatFits(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50))
        self.mapView.setRegion(MKCoordinateRegion(visibleMapRect), animated: true)
        while index < annotations.count - 1 {
            drawDirection(startPoint: annotations[index].coordinate, endPoint: annotations[index + 1].coordinate)
            index += 1
        }
    }
    
    @IBAction func removeAnnotations() {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(annotations)
        
        annotations.removeAll()
    }
    
    func drawDirection(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
        let startPlacemark = MKPlacemark(coordinate: startPoint, addressDictionary: nil)
        let endPlacemark = MKPlacemark(coordinate: endPoint, addressDictionary: nil)
        let startMapItem = MKMapItem(placemark: startPlacemark)
        let endMapItem = MKMapItem(placemark: endPlacemark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = startMapItem
        directionRequest.destination = endMapItem
        directionRequest.transportType = MKDirectionsTransportType.automobile
        
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate { (routeResponse, routeError) -> Void in
            guard let routeResponse = routeResponse else {
                if let routeError = routeError {
                    print(routeError)
                }
                return
            }
            
            let route = routeResponse.routes[0]
            self.mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
        }
    }
    
}
