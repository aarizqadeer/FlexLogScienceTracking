//
//  Typography.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import SwiftUI

enum Typography {
    static let title = Font.system(.title, design: .rounded).weight(.bold)
    static let subtitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded)
}
