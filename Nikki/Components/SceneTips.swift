//
//  SceneTips.swift
//  Nikki
//
//  Created by Rafael Toneto on 09/12/25.
//

import TipKit
import SwiftUI

struct NewPageTip: Tip {
    var title: Text {
        Text("Create a new page")
    }

    var message: Text? {
        Text("Tap here to write a new memory in your journal.")
    }

    var image: Image? {
        Image(systemName: "plus.circle.fill")
    }
}

struct FocusTsuruTip: Tip {
    var title: Text {
        Text("Find your origamis")
    }

    var message: Text? {
        Text("Use this button to focus the camera on your origami pages.")
    }

    var image: Image? {
        Image(systemName: "location")
    }
}
