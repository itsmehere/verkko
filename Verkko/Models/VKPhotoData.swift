//
//  VKPhotoData.swift
//  Verkko
//
//  Created by Mihir Rao on 8/16/23.
//

import UIKit

struct VKPhotoData: Hashable, Codable {
    var photoID: String
    var name1: String
    var name2: String
    var pfp1: Data?
    var pfp2: Data?
    var date: Date
    var lat: Double
    var lon: Double
    
    func getPFP1() -> UIImage? {
        if let imageData = pfp1, let image = UIImage(data: imageData) {
            return image
        }
        return nil
    }
    
    func getPFP2() -> UIImage? {
        if let imageData = pfp2, let image = UIImage(data: imageData) {
            return image
        }
        return nil
    }
    
    func copy() -> Any {
        let copy = VKPhotoData(photoID: photoID, name1: name1, name2: name2, pfp1: pfp1, pfp2: pfp2, date: date, lat: lat, lon: lon)
        return copy
    }
}
