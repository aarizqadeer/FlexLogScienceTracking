//
//  ProgressMetric.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation

struct ProgressMetric: Identifiable {
    let id: UUID
    let title: String
    let value: String
    let trend: String

    init(id: UUID = UUID(), title: String, value: String, trend: String) {
        self.id = id
        self.title = title
        self.value = value
        self.trend = trend
    }
}
