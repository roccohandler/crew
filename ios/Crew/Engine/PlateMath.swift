// SPEC: Flow 3 plate math — tap-hold a barbell weight → "45 + 25 + 2.5 per side". Twin of plate-math.ts.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct PlateBreakdown: Equatable {
    let perSide: [Double]
    let reachableTotal: Double
    let exact: Bool
}

enum PlateMath {
    static func platesPerSide(totalWeight: Double, units: String) -> PlateBreakdown {
        let bar = units == "lb" ? Double(SpecConstants.barbellBarWeightLb) : Double(SpecConstants.barbellBarWeightKg)
        let plates = units == "lb" ? SpecConstants.plateSetLb : SpecConstants.plateSetKg
        var perSide: [Double] = []
        var remaining = max(0, totalWeight - bar) / Double(SpecConstants.barbellPlateSides)
        for plate in plates {
            while remaining + Double.ulpOfOne >= plate {
                perSide.append(plate)
                remaining -= plate
            }
        }
        let loaded = perSide.reduce(0, +)
        let reachable = bar + loaded + loaded
        return PlateBreakdown(perSide: perSide, reachableTotal: reachable, exact: abs(reachable - totalWeight) < Double.ulpOfOne && totalWeight >= bar)
    }

    static func plateLine(totalWeight: Double, units: String) -> String {
        let breakdown = platesPerSide(totalWeight: totalWeight, units: units)
        if breakdown.perSide.isEmpty { return "just the bar" }
        return breakdown.perSide.map { $0.truncatingRemainder(dividingBy: 1) == 0 ? String(Int($0)) : String($0) }.joined(separator: " + ") + " per side"
    }
}
