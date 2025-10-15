//
//  ProgressScreen.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import SwiftUI
import CoreData

struct ProgressScreen: View {
    @StateObject private var viewModel: ProgressViewModel

    init(viewModel: ProgressViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(viewModel.metrics) { metric in
                        ProgressMetricCard(metric: metric)
                            .transition(.scale)
                    }
                }
                .padding(24)
            }
            .background(Color.flexBackground.ignoresSafeArea())
            .navigationTitle("Progress")
        }
        .task { await viewModel.loadMetrics() }
    }
}

struct ProgressMetricCard: View {
    let metric: ProgressMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(metric.title)
                .font(.headline)
                .foregroundStyle(Color.flexOnSurface)
            Text(metric.value)
                .font(.largeTitle.bold())
                .foregroundStyle(Color.flexPrimary)
            Text(metric.trend)
                .font(.callout.weight(.medium))
                .foregroundStyle(metric.trend.contains("-") ? Color.flexNegative : Color.flexPositive)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.flexSurface)
                .shadow(color: Color.black.opacity(0.08), radius: 10, y: 5)
        )
    }
}

#Preview {
    ProgressScreen(viewModel: ProgressViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
