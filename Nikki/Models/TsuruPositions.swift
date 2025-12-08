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
        case .pos1:  SIMD3(-3.77,  0.19, 1.87)
        case .pos2:  SIMD3(-3.54, 0.05, 2.026)
        case .pos3:  SIMD3(-3.06, 0.13, 1.85)
        case .pos4:  SIMD3(-3.12, 0.17, 1.39)
        case .pos5:  SIMD3(-2.53, -0.396, 2.2)
        case .pos6:  SIMD3(-2.26, -0.54, 1.999)
        case .pos7:  SIMD3(-1.93, -0.786, 1.88)
        case .pos8:  SIMD3(-3.03, 0.199, 1.052)
        case .pos9:  SIMD3(-0.976, 0.44, 1.153)
        case .pos10: SIMD3(-0.879,  0.53, 0.856)
        case .pos11: SIMD3(-2.53,  -0.52, 4.97)
        case .pos12: SIMD3(-2.2,  -0.37, 4.998)
        case .pos13: SIMD3(-1.878,  -0.25, 5.12)
        case .pos14: SIMD3(-1.17,  0.27, 5.398)
        case .pos15: SIMD3(-1.45,  -0.26, 5.24)
        case .pos16: SIMD3(-0.85,  0.55, 5.398)
        case .pos17: SIMD3(-4.198, 0.27, 3.91)
        case .pos18: SIMD3(-4.34, 0.56, 4.14)
        case .pos19: SIMD3(-4.53, 1.03, 4.48)
        case .pos20: SIMD3(-4.75, 1.199, 4.767)
        case .pos21: SIMD3(-5.05, 1.577, 4.767)
        case .pos22: SIMD3(-2.44, -0.516, 3.694)
        case .pos23: SIMD3(-2.308, -0.327, 3.325)
        case .pos24: SIMD3(-3.44, -0.12, 4.908)
        case .pos25: SIMD3(-3.34, 0.29, 5.22)
        case .pos26: SIMD3(-2.32, 0.14, 1.856)
        case .pos27: SIMD3(0.465, 0.17, 3.51)
        case .pos28: SIMD3(-3.73, 0.72, 5.769)
        case .pos29: SIMD3(-3.84, 0.84, 6.21)
        case .pos30: SIMD3(-3.565, 1.017, 5.55)
        }
    }}

