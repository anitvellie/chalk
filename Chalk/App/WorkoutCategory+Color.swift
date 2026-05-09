// WorkoutCategory+Color.swift
// Chalk — View-layer colour mapping (app target only)
//
// Forwards to WorkoutColorMapping (Shared) which is also compiled into the
// widget extension, keeping the mapping in a single source of truth.

import SwiftUI

extension WorkoutCategory {
    var displayColor: Color { WorkoutColorMapping.color(for: icon) }
}
