import Testing
import simd
@testable import Nikki

@Suite("BonsaiTsuruLayout")
struct BonsaiTsuruLayoutTest {

    @Test func hasOnePositionPerTsuru() {
        #expect(BonsaiTsuruLayout.tsuruCount == 5)
        #expect(BonsaiTsuruLayout.positions.count == BonsaiTsuruLayout.tsuruCount)
    }

    @Test func azimuthsAreEvenlySpaced() {
        let azimuths = BonsaiTsuruLayout.positions.map { atan2($0.z, $0.x) }
        let step = 2 * Float.pi / Float(BonsaiTsuruLayout.tsuruCount)

        for index in 1..<azimuths.count {
            let rawDelta = azimuths[index] - azimuths[index - 1]
            let delta = atan2(sin(rawDelta), cos(rawDelta))
            #expect(abs(abs(delta) - step) < 0.001)
        }
    }

    @Test func positionsStayWithinCanopy() {
        for position in BonsaiTsuruLayout.positions {
            let radius = (position.x * position.x + position.z * position.z).squareRoot()
            #expect(radius >= 60 && radius <= 120)
            #expect(position.y >= 150 && position.y <= 245)
        }
    }

    @Test func yawVariesAroundFrontFacing() {
        let yaws = (0..<BonsaiTsuruLayout.tsuruCount).map { BonsaiTsuruLayout.yaw(at: $0) }
        #expect(Set(yaws).count > 1)
        for yaw in yaws {
            #expect(abs(yaw - .pi) <= 0.5)
        }
    }

    @Test func tsuruScaleHitsTargetFraction() {
        let canopy = SIMD3<Float>(544, 300, 502)
        let native = SIMD3<Float>(2, 2, 2)
        let scale = BonsaiTsuruLayout.tsuruScale(canopyExtents: canopy, tsuruNativeExtents: native)
        #expect(abs(scale - 3) < 0.001)
        #expect(abs(native.y * scale - canopy.y * 0.02) < 0.001)
    }

    @Test func tsuruScaleHandlesZeroNative() {
        let scale = BonsaiTsuruLayout.tsuruScale(
            canopyExtents: SIMD3<Float>(1, 1, 1),
            tsuruNativeExtents: .zero
        )
        #expect(scale.isFinite)
    }
}
