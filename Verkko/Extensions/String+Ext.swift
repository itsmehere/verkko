//
//  String+Ext.swift
//  Verkko
//
//  Created by Justin Wong on 8/22/23.
//

import Foundation

extension String {
    func capitalizeFirstAndLowercaseRest() -> String {
        let lowercaseInput = self.lowercased()
        let firstCharacter = lowercaseInput.first?.uppercased() ?? ""
        let remainingCharacters = String(lowercaseInput.dropFirst())
        
        return firstCharacter + remainingCharacters
    }
}
