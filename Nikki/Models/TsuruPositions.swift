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
        case .pos1:  SIMD3(-1.925,  -1.408, 6.489) // ok
        case .pos2:  SIMD3(-4.242, 0.049, 6.735) // ok
        case .pos3:  SIMD3(-4.936, 0.067, 6.735) // ok
        case .pos4:  SIMD3(-3.686, 0.305, 6.735) // ok
        case .pos5:  SIMD3(-1.191, -0.903, 6.735) // ok
        case .pos6:  SIMD3(-1.951, 0.448, 6.735) // ok
        case .pos7:  SIMD3(-4.415, 1.012, 7.122) // ok
        case .pos8:  SIMD3(-6.257, 1.728, 8.319) // ok
        case .pos9:  SIMD3(-5.194, 1.663, 8.319) // ok
        case .pos10: SIMD3(-1.937,  1.44, 7.582) // ok
        case .pos11: SIMD3(-2.53,  -0.52, 4.97) // ok
        case .pos12: SIMD3(-5.733,  2.354, 7.313) // ok
        case .pos13: SIMD3(-6.206,  2.431, 6.157) // ok
        case .pos14: SIMD3(-7.034,  1.764, 5.8) // ok
        case .pos15: SIMD3(-7.034,  1.899, 5.076) // ok
        case .pos16: SIMD3(-5.57,  2.113, 4.529) // ok
        case .pos17: SIMD3(-4.279, 3.631, 7.511) // ok
        case .pos18: SIMD3(-3.221, 3.577, 7.229) // ok
        case .pos19: SIMD3(-0.571, 0.642, 6.198) // ok
        case .pos20: SIMD3(0.22, 0.538, 4.694) // ok
        case .pos21: SIMD3(-0.637, 1.607, 6.601) // ok
        case .pos22: SIMD3(-1.996, 2.187, 6.895) // ok
        case .pos23: SIMD3(-6.713, 2.187, 5.958) // ok
        case .pos24: SIMD3(-2.297, 3.108, 5.568) // ok
        case .pos25: SIMD3(-5.902, 3.89, 6.583) // ok
        case .pos26: SIMD3(-0.928, 2.77, 4.404) // ok
        case .pos27: SIMD3(-4.128, 2.887, 7.149) // ok
        case .pos28: SIMD3(-2.999, 4.247, 6.626) // ok
        case .pos29: SIMD3(-4.462, 3.755, 6.626) // ok
        case .pos30: SIMD3(-6.773, 3.387, 5.063) // ok
        }
    }}

