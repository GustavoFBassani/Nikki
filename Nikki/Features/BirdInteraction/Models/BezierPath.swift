//
//  BezierPath.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

#if os(visionOS)
import simd

/// Uma curva Bézier cúbica no espaço 3D, com pontos nomeados de forma legível
/// (`start` / `controlA` / `controlB` / `end`) em vez de `p0…p3`. Expõe o
/// ponto e a tangente em um parâmetro `t está no intervalo [0, 1]`.
struct BezierPath {
    let start: SIMD3<Float>
    let controlA: SIMD3<Float>
    let controlB: SIMD3<Float>
    let end: SIMD3<Float>

    /// Posição na curva no parâmetro `t`.
    func point(at t: Float) -> SIMD3<Float> {
        let u = 1 - t
        return u * u * u * start
            + 3 * u * u * t * controlA
            + 3 * u * t * t * controlB
            + t * t * t * end
    }

    /// Tangente (direção do movimento) na curva no parâmetro `t`.
    func tangent(at t: Float) -> SIMD3<Float> {
        let u = 1 - t
        return 3 * u * u * (controlA - start)
            + 6 * u * t * (controlB - controlA)
            + 3 * t * t * (end - controlB)
    }
}
#endif
