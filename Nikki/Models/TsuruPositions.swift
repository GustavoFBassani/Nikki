//
//  TsuruPositions.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 06/12/25.
//

enum TsuruPosition: CaseIterable {
    case pos1, pos2, pos3, pos4, pos5,
         pos6, pos7, pos8, pos9, pos10,
         pos11, pos12, pos13, pos14, pos15,
         pos16, pos17, pos18, pos19, pos20,
         pos21, pos22, pos23, pos24, pos25,
         pos26, pos27, pos28, pos29, pos30

    var position: SIMD3<Float> {
        switch self {
        case .pos1:  SIMD3(-1.7,  0.4, 1.6)
        case .pos2:  SIMD3(-2.8, -0.7, 2.5)
        case .pos3:  SIMD3(-2.6, -0.9, 2.4)
        case .pos4:  SIMD3(-3.1, -0.5, 2.7)
        case .pos5:  SIMD3(-3.4, -0.3, 3.1)
        case .pos6:  SIMD3(-3.6, -0.3, 3.3)
        case .pos7:  SIMD3(-2.8, -0.4, 5.0)
        case .pos8:  SIMD3(-3.2, -0.5, 5.0)
        case .pos9:  SIMD3(-4.1, -0.4, 5.4)
        case .pos10: SIMD3(-4.1,  0.0, 5.7)
        case .pos11: SIMD3(-5.1,  1.8, 5.8)
        case .pos12: SIMD3(-6.0,  1.7, 5.6)
        case .pos13: SIMD3(-5.8,  1.4, 5.4)
        case .pos14: SIMD3(-5.3,  0.9, 5.1)
        case .pos15: SIMD3(-5.1,  0.5, 4.9)
        case .pos16: SIMD3(-2.0,  0.3, 1.9)
        case .pos17: SIMD3(-3.09, 0.67, 4.58)
        case .pos18: SIMD3(-3.0, 0.86, 4.35)
        case .pos19: SIMD3(-2.87, 1.01, 4.14)
        case .pos20: SIMD3(-2.79, 1.2, 3.95)
        case .pos21: SIMD3(-2.69, 1.56, 3.97)
        case .pos22: SIMD3(-2.66, 1.59, 5.01)
        case .pos23: SIMD3(-2.35, 1.6, 5.1)
        case .pos24: SIMD3(-2.36, 1.8, 5.3)
        case .pos25: SIMD3(-2.2, 1.9, 5.5)
        case .pos26: SIMD3(-3.38, 0.69, 4.47)
        case .pos27: SIMD3(-3.23, 0.67, 4.26)
        case .pos28: SIMD3(-3.04, 0.66, 4.1)
        case .pos29: SIMD3(-2.78, 0.41, 4.118)
        case .pos30: SIMD3(-2.54, 0.28, 4.08)
        }
    }
}

