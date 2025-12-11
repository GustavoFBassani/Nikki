//
//  SceneTips.swift
//  Nikki
//
//  Created by Rafael Toneto on 09/12/25.
//

import SwiftUI
import TipKit

struct NewPageTip: Tip {
    var title: Text { Text("Create your scrap") }
    var message: Text? {
        Text("After finishing, it will transform into an origami in the scene.")
            .foregroundStyle(.blueNikki)
    }

    var actions: [Tip.Action] { [] }
}

struct FocusTsuruTip: Tip {
    var title: Text {
        Text("Localize your origamis")
    }
    
    var message: Text? {
        Text("Find your scraps easily")
            .foregroundStyle(.blueNikki)
    }
}
