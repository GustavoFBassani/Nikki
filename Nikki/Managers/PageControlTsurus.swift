//
//  PageControlTsurus.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 09/12/25.
//

import RealityKit

class PageControlTsurus {
    
    var currentPageControl: Int = 0 //controle do fluxo

    func navigateToTsuru(
        at side: String,
        orderedEntities: [Entity],
        selectedPage: inout Page?,
        dict: inout [Entity: Page],
        repositioningCameraToTsuru: (Entity)->Void
    ) {
        if side == "left"  { // ir para traz
            let nextEntity = orderedEntities[currentPageControl+1]
            repositioningCameraToTsuru(nextEntity)
            selectedPage = dict[nextEntity]
            currentPageControl += 1
        }
        
        if side == "right" { // ir para frente
            let nextEntity = orderedEntities[currentPageControl-1]
            selectedPage = dict[nextEntity]
            repositioningCameraToTsuru(nextEntity)
            currentPageControl -= 1
        }
    }
    
    
    func resetPageControl() {
        currentPageControl = 0
    }
    
    
}
