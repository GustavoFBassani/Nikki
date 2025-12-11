//
//  SceneTips.swift
//  Nikki
//
//  Created by Rafael Toneto on 09/12/25.
//

import SwiftUI
import TipKit

struct NewPageTip: Tip {
    var title: Text { Text("Crie seu scrap") }
    var message: Text? {
        Text("Após finalizar ele irá se transformar em um origami no cenário")
            .foregroundStyle(.tipMessage)
    }

    var actions: [Tip.Action] { [] }
}

struct FocusTsuruTip: Tip {
    var title: Text {
        Text("Localize seus origamis")
    }
    
    var message: Text? {
        Text("Encontre suas colagens facilmente")
            .foregroundStyle(.tipMessage)
    }
}
