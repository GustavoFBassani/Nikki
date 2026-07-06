//
//  BonsaiTsuruLayout.swift
//  Nikki
//
//  Created by Anthony Antonelli Andrade on 22/06/26.
//

import simd
import Foundation

// Distribui os tsurus decorativos pela copa do bonsai.
// Valores em coordenadas locais da árvore, antes da escala do modelo
// (a copa da Cherry_Tree-2 tem ~300 de altura e ~250 de raio nessas unidades).
enum BonsaiTsuruLayout {

    static let tsuruCount = 5

    // Raio horizontal e altura de cada tsuru; variados para não formar um anel rígido.
    private static let radii: [Float] = [72, 96, 80, 104, 88]
    private static let heights: [Float] = [158, 214, 178, 238, 198]

    // Primeiro tsuru de frente para o usuário (janela abre em -Z).
    private static let startAngle: Float = -.pi / 2

    // Azimutes igualmente espaçados ao redor da copa.
    static let positions: [SIMD3<Float>] = (0..<tsuruCount).map { index in
        let angle = startAngle + Float(index) * (2 * .pi / Float(tsuruCount))
        return SIMD3<Float>(
            cos(angle) * radii[index],
            heights[index],
            sin(angle) * radii[index]
        )
    }

    // Rotação em Y: frente do modelo virada para o usuário (.pi),
    // com leve variação por tsuru para um resultado mais orgânico.
    static func yaw(at index: Int) -> Float {
        let variations: [Float] = [0, 0.35, -0.3, 0.2, -0.4]
        return .pi + variations[index % variations.count]
    }

    // Escala para o tsuru ocupar `heightFraction` da altura da copa.
    static func tsuruScale(
        canopyExtents: SIMD3<Float>,
        tsuruNativeExtents: SIMD3<Float>,
        heightFraction: Float = 0.02
    ) -> Float {
        let tsuruHeight = max(tsuruNativeExtents.y, 0.0001)
        return canopyExtents.y * heightFraction / tsuruHeight
    }
}
