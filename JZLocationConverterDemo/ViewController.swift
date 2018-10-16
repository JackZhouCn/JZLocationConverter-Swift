//
//  ViewController.swift
//  JZLocationConverter-Swift
//
//  Created by jack zhou on 20/07/2017.
//  Copyright © 2017 Jack. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView:MKMapView!
    @IBOutlet weak var label:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let p:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(press(recognizer:)))
        mapView.addGestureRecognizer(p)
    }
    
    @objc func press(recognizer:UIGestureRecognizer) -> Void {
        if recognizer.state == .began {
            let touchPoint:CGPoint = recognizer.location(in: mapView)
            let touchMapCoordinate:CLLocationCoordinate2D = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            JZLocationConverter.default.gcj02ToBd09(touchMapCoordinate, result: { (bd09:CLLocationCoordinate2D) in
                JZLocationConverter.default.gcj02ToWgs84(touchMapCoordinate, result: { (wgs84:CLLocationCoordinate2D) in
                    JZAreaManager.default.isOutOfArea(gcj02Point: touchMapCoordinate, result: { (isOut:Bool) in
                        self.label.text = "GCJ02：\(self.formatter(touchMapCoordinate))\nBD09：\(self.formatter(bd09))\nWGS84：\(self.formatter(wgs84))\n大陆：\(isOut ? "否" : "是")"
                    })
                    
                })
            })
        }
    }
    
    private func formatter(_ p:CLLocationCoordinate2D) -> String {
        return String(format: "%.6f,%.6f",p.latitude,p.longitude)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController:MKMapViewDelegate {
    
}

