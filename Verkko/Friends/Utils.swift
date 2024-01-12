//
//  Utils.swift
//  Verkko
//
//  Created by Mihir Rao on 6/20/23.
//

import UIKit
import MapKit

class Utils {
    static func getAddressFromLatLon(lat: Double, lon: Double, completed: @escaping (Result<String, Error>) -> Void) {
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = lat
        center.longitude = lon

        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)

        ceo.reverseGeocodeLocation(loc, completionHandler: {(placemarks, error) in
            if (error != nil) {
                completed(.failure(error!))
            }
            guard let placemarks = placemarks else {
                completed(.success(""))
                return
            }
            
            let pm = placemarks as [CLPlacemark]

            if pm.count > 0 {
                let pm = placemarks[0]
                var addressString : String = ""

                if pm.subLocality != nil {
                    addressString = addressString + pm.subLocality! + ", "
                }
                
                if pm.thoroughfare != nil {
                    addressString = addressString + pm.thoroughfare! + ", "
                }
            
                if pm.locality != nil {
                    addressString = addressString + pm.locality! + ", "
                }
                
                if pm.country != nil {
                    addressString = addressString + pm.country! + ", "
                }
                
                if pm.postalCode != nil {
                    addressString = addressString + pm.postalCode! + " "
                }
                
                completed(.success(addressString))
            }
        })
    }
    
    static func getLastSeenTime(dateStamp: Date) -> String {
        let secondsAgo = Int(Date().timeIntervalSince(dateStamp))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day

        if secondsAgo < minute {
            return "\(secondsAgo)s"
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute)min"
        } else if secondsAgo < day {
            return "\(secondsAgo / hour)hr"
        } else if secondsAgo < week {
            return "\(secondsAgo / day)d"
        }

        return "\(secondsAgo / week)w"
    }
    
    static func ddMMYY(dateStamp: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: dateStamp)
        return dateString
    }
    
    static func getFormattedLengthyEllipseText(labelText: String, maxLength: Int) -> String{
        var labelText = labelText
        
        if labelText.count > maxLength {
            let index = labelText.index(labelText.startIndex, offsetBy: maxLength - 3)
            
            labelText = String(labelText[..<index])
            labelText = labelText + "..."
        }
        
        return labelText
    }
    
    static func getFormattedMutualFriendsString(mutualFriends: [VKUser], totalMutualFriends: Int) -> String {
        if mutualFriends.count == 0 {
            return "0 mutual friends"
        } else if mutualFriends.count == 1 {
            return mutualFriends[0].firstName + " is a mutual friend"
        } else if mutualFriends.count == totalMutualFriends {
            var mutualFriendNameString = ""
            
            mutualFriendNameString += mutualFriends[0].firstName + " and "
            mutualFriendNameString += mutualFriends[1].firstName + " are mutual friends"
            
            return mutualFriendNameString
        } else {
            var mutualFriendNameString = ""
            
            for mutualFriend in mutualFriends {
                mutualFriendNameString += mutualFriend.firstName + ", "
            }
            
            return mutualFriendNameString + "and " + String(totalMutualFriends - mutualFriends.count) + " other\nmutual friends"
        }
    }
    
    @objc static func launchMaps(location: CLLocationCoordinate2D, address: String) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location, addressDictionary: nil))
        mapItem.name = address.components(separatedBy: ", ")[0]
        mapItem.openInMaps()
    }
    
    static func factorial(_ n: Int) -> Int {
        if n == 0 {
            return 1
        }
        
        var res = 1
        
        for i in 1...n {
            res *= i
        }
        
        return res
    }
    
    static func numberOfCombinations(n: Int, k: Int) -> Int {
        return factorial(n) / (factorial(k) * factorial(n - k))
    }

    // MARK: Not Currently Used
    static func getAverageColorOfImage(image: UIImage?) -> UIColor? {
        if let image = image {
            guard let inputImage = CIImage(image: image) else { return nil }
            let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)

            guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
            guard let outputImage = filter.outputImage else { return nil }

            var bitmap = [UInt8](repeating: 0, count: 4)
            let context = CIContext(options: [.workingColorSpace: kCFNull!])
            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

            return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
        } else {
            return .white
        }
    }
    
    static func roundToTheFifthDecimalPlace(for double: Double) -> Double {
        return round(double * 100000) / 100000
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: email.utf16.count)
        return regex?.firstMatch(in: email, options: [], range: range) != nil
    }
}
