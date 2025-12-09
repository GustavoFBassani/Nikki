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
    }
}

struct FocusTsuruTip: Tip {
    var title: Text {
        Text("Volte para o seu tsuru")
    }
    
    var message: Text? {
        Text("Use este botão para focar rapidamente no seu último origami na árvore.")
    }
}
