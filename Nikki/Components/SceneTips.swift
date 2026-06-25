//
//  SceneTips.swift
//  Nikki
//
//  Created by Rafael Toneto on 09/12/25.
//

import SwiftUI
import TipKit

struct NewPageTip: Tip {
    var title: Text { Text(StringCatalog.createYourScrap) }
    var message: Text? {
        Text(StringCatalog.afterFinishItWillTransform)
            .foregroundStyle(.tipMessage)
    }

    var actions: [Tip.Action] { [] }
}

struct FocusTsuruTip: Tip {
    var title: Text {
        Text(StringCatalog.localizeYourOrigamis)
    }
    
    var message: Text? {
        Text(StringCatalog.findYourCollages)
            .foregroundStyle(.tipMessage)
    }
}
