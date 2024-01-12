//
//  VKHostingController.swift
//  Verkko
//
//  Created by Justin Wong on 6/3/23.
//

import SwiftUI

class VKHostingController<ContentView: View>: UIHostingController<ContentView> {
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(true)
      navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
