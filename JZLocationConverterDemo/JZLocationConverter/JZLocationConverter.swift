//
//  JZLocationConverter.swift
//  JZLocationConverter-Swift
//
//  Created by jack zhou on 21/07/2017.
//  Copyright © 2017 Jack. All rights reserved.
//

import Foundation
import CoreLocation
extension CLLocationCoordinate2D {
    struct JZConstant {
        static let A = 6378245.0
        static let EE = 0.00669342162296594323
    }
    func gcj02Offset() -> CLLocationCoordinate2D {
        let x = self.longitude - 105.0
        let y = self.latitude - 35.0
        let latitude = (-100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x))) +
                        ((20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0) +
                            ((20.0 * sin(y * .pi) + 40.0 * sin(y / 3.0 * .pi)) * 2.0 / 3.0) +
                                ((160.0 * sin(y / 12.0 * .pi) + 320 * sin(y * .pi / 30.0)) * 2.0 / 3.0)
        let longitude = (300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x))) +
                            ((20.0 * sin(6.0 * x * .pi) + 20.0 * sin(2.0 * x * .pi)) * 2.0 / 3.0) +
                                ((20.0 * sin(x * .pi) + 40.0 * sin(x / 3.0 * .pi)) * 2.0 / 3.0) +
                                    ((150.0 * sin(x / 12.0 * .pi) + 300.0 * sin(x / 30.0 * .pi)) * 2.0 / 3.0)
        let radLat = 1 - self.latitude / 180.0 * .pi;
        var magic = sin(radLat);
        magic = 1 - JZConstant.EE * magic * magic
        let sqrtMagic = sqrt(magic);
        let dLat = (latitude * 180.0) / ((JZConstant.A * (1 - JZConstant.EE)) / (magic * sqrtMagic) * .pi);
        let dLon = (longitude * 180.0) / (JZConstant.A / sqrtMagic * cos(radLat) * .pi);
        return CLLocationCoordinate2DMake(dLat, dLon);
    }
}

open class JZLocationConverter {
    
    fileprivate let queue = DispatchQueue(label: "JZ.LocationConverter.Converter")
    public static let `default`: JZLocationConverter = {
        return JZLocationConverter()
    }()
    
    open static func start(filePath:String!,finished:((_ error:JZFileError?) -> Void)?) {
        JZAreaManager.start(filePath: filePath, finished: finished)
    }


}

//GCJ02
extension JZLocationConverter {
    fileprivate func gcj02Encrypt(_ wgs84Point:CLLocationCoordinate2D,result:@escaping (_ gcj02Point:CLLocationCoordinate2D) -> Void) {
        self.queue.async {
            let offsetPoint = wgs84Point.gcj02Offset()
            let resultPoint = CLLocationCoordinate2DMake(wgs84Point.latitude + offsetPoint.latitude, wgs84Point.longitude + offsetPoint.longitude)
            JZAreaManager.default.isOutOfArea(gcj02Point: resultPoint, result: { (isOut:Bool) in
                DispatchQueue.main.async {
                    if isOut {
                        result(wgs84Point)
                    }else {
                        result(resultPoint)
                    }
                }
            })
        }
    }

    fileprivate func gcj02Decrypt(_ gcj02Point:CLLocationCoordinate2D,result:@escaping (_ wgs84Point:CLLocationCoordinate2D) -> Void) {
        JZAreaManager.default.isOutOfArea(gcj02Point: gcj02Point, result: { (isOut:Bool) in
            if isOut {
                DispatchQueue.main.async {
                    result(gcj02Point)
                }
            }else {
                self.gcj02Encrypt(gcj02Point) { (mgPoint:CLLocationCoordinate2D) in
                    self.queue.async {
                        let resultPoint = CLLocationCoordinate2DMake(gcj02Point.latitude * 2 - mgPoint.latitude,gcj02Point.longitude * 2 - mgPoint.longitude)
                        DispatchQueue.main.async {
                            result(resultPoint)
                        }
                    }
                }
            }
        })
    }
}

//BD09
extension JZLocationConverter {
    fileprivate func bd09Encrypt(_ gcj02Point:CLLocationCoordinate2D,result:@escaping (_ bd09Point:CLLocationCoordinate2D) -> Void) {
        self.queue.async {
            let x = gcj02Point.longitude
            let y = gcj02Point.latitude
            let z = sqrt(x * x + y * y) + 0.00002 * sin(y * .pi);
            let theta = atan2(y, x) + 0.000003 * cos(x * .pi);
            let resultPoint = CLLocationCoordinate2DMake(z * sin(theta) + 0.006, z * cos(theta) + 0.0065)
            DispatchQueue.main.async {
                result(resultPoint)
            }
        }
    }

    fileprivate func bd09Decrypt(_ bd09Point:CLLocationCoordinate2D,result:@escaping (_ gcj02Point:CLLocationCoordinate2D) -> Void) {
        self.queue.async {
            let x = bd09Point.longitude - 0.0065
            let y = bd09Point.latitude - 0.006
            let z = sqrt(x * x + y * y) - 0.00002 * sin(y * .pi);
            let theta = atan2(y, x) - 0.000003 * cos(x * .pi);
            let resultPoint = CLLocationCoordinate2DMake(z * sin(theta), z * cos(theta))
            DispatchQueue.main.async {
                result(resultPoint)
            }
        }
    }
}

extension JZLocationConverter {
    public func wgs84ToGcj02(_ wgs84Point:CLLocationCoordinate2D,result:@escaping (_ gcj02Point:CLLocationCoordinate2D) -> Void) {
        self.gcj02Encrypt(wgs84Point, result: result)
    }
    
    public func wgs84ToBd09(_ wgs84Point:CLLocationCoordinate2D,result:@escaping (_ bd09Point:CLLocationCoordinate2D) -> Void) {
        self.gcj02Encrypt(wgs84Point) { (gcj02Point:CLLocationCoordinate2D) in
            self.bd09Encrypt(gcj02Point, result: result);
        }
    }
    
    public func gcj02ToWgs84(_ gcj02Point:CLLocationCoordinate2D,result:@escaping (_ wgs84Point:CLLocationCoordinate2D) -> Void) {
        self.gcj02Decrypt(gcj02Point, result: result)
    }
    
    public func gcj02ToBd09(_ gcj02Point:CLLocationCoordinate2D,result:@escaping (_ bd09Point:CLLocationCoordinate2D) -> Void) {
        self.bd09Encrypt(gcj02Point, result: result);
    }
    
    public func bd09ToGcj02(_ bd09Point:CLLocationCoordinate2D,result:@escaping (_ gcj02Point:CLLocationCoordinate2D) -> Void) {
        self.bd09Decrypt(bd09Point, result: result)
    }
    
    public func bd09ToWgs84(_ bd09Point:CLLocationCoordinate2D,result:@escaping (_ wgs84Point:CLLocationCoordinate2D) -> Void) {
        self.bd09Decrypt(bd09Point) { (gcj02Point:CLLocationCoordinate2D) in
            self.gcj02Decrypt(gcj02Point, result: result);
        }
    }
}

