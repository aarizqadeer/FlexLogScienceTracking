//
//  ProgressHighlight.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation

struct ProgressHighlight: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let change: String
    let icon: String
    let isPositive: Bool

    init(id: UUID = UUID(), title: String, subtitle: String, change: String, icon: String, isPositive: Bool) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.change = change
        self.icon = icon
        self.isPositive = isPositive
    }
}

extension ProgressHighlight {
    static let sample: [ProgressHighlight] = [
        ProgressHighlight(title: "Bench Press", subtitle: "+5 kg in 4 weeks", change: "+4%", icon: "chart.line.uptrend.xyaxis", isPositive: true),
        ProgressHighlight(title: "Weekly Volume", subtitle: "Consistent progression", change: "+8%", icon: "figure.strengthtraining.traditional", isPositive: true),
        ProgressHighlight(title: "Mobility Score", subtitle: "Room to improve", change: "-2%", icon: "figure.cooldown", isPositive: false),
        ProgressHighlight(title: "Sleep Quality", subtitle: "Stable recovery", change: "0%", icon: "bed.double.fill", isPositive: true)
    ]
}
