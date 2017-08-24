//
//  JZAreaManager.swift
//  JZLocationConverterDemo
//
//  Created by jack zhou on 23/08/2017.
//  Copyright © 2017 Jack. All rights reserved.
//
import Foundation
import CoreLocation

public enum JZFileError: Error {
    case FileNotFound
    case EmptyData
    case invalidData
}
open class JZAreaManager {
    
    private(set) var points:Array<Array<Double>>?
    
    fileprivate let queue = DispatchQueue(label: "JZ.LocationConverter.AreaManager")
    
    public static let `default`: JZAreaManager = {
        return JZAreaManager()
    }()
    
    public static func start(filePath:String!,finished:((_ error:JZFileError?) -> Void)?) {
        JZAreaManager.default.queue.async {
            guard let jsonString = try? String(contentsOfFile: filePath) else {
                DispatchQueue.main.async {
                    if finished != nil {
                        finished!(JZFileError.EmptyData)
                    }
                }
                return
            }
            guard let data = jsonString.data(using: .utf8) else {
                DispatchQueue.main.async {
                    if finished != nil {
                        finished!(JZFileError.invalidData)
                    }
                }
                return
            }
            guard let array = try? JSONSerialization.jsonObject(with: data, options: []) else {
                DispatchQueue.main.async {
                    if finished != nil {
                        finished!(JZFileError.invalidData)
                    }
                }
                return
            }
            JZAreaManager.default.points = array as? Array<Array<Double>>
            DispatchQueue.main.async {
                if finished != nil {
                    finished!(nil)
                }
            }
        }
    }
    
    public func isOutOfArea(gcj02Point:CLLocationCoordinate2D,result:@escaping ((_ result:Bool)->Void)) -> Void {
        self.queue.async {
            var flag = false
            if JZAreaManager.default.points != nil {
                let length = (JZAreaManager.default.points?.count)!
                for idx in 0 ..< length {
                    let nextIdx = (idx + 1) == length ? 0 : idx + 1
                    let edgePoint = JZAreaManager.default.points![idx]
                    let nextPoint = JZAreaManager.default.points![nextIdx]
                    
                    let pointX = edgePoint[1]
                    let pointY = edgePoint[0]
                    
                    let nextPointX = nextPoint[1]
                    let nextPointY = nextPoint[0]
                    
                    if (gcj02Point.longitude == pointX && gcj02Point.latitude == pointY) ||
                        (gcj02Point.longitude == nextPointX && gcj02Point.latitude == nextPointY)  {
                        flag = true
                    }
                    if((nextPointY < gcj02Point.latitude && pointY >= gcj02Point.latitude) ||
                        (nextPointY >= gcj02Point.latitude && pointY < gcj02Point.latitude)) {
                        let thX = nextPointX + (gcj02Point.latitude - nextPointY) * (pointX - nextPointX) / (pointY - nextPointY)
                        if(thX == gcj02Point.longitude) {
                            flag = true
                            break
                        }
                        if(thX > gcj02Point.longitude) {
                            flag = !flag
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                result(!flag)
            }
        }
    }
}
