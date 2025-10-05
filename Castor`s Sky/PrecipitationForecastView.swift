//
//  PrecipitationForecastView.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI
import Charts
import MapKit

struct PrecipitationForecastView: View {
    @StateObject private var hydrologyManager = NASAHydrologyManager()
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingRainyDays = true
    @State private var resolvedPlaceName: String?
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case threeMonths = "90 Days"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Space-themed background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.11, blue: 0.23), // #0B1D3A
                    Color(red: 0.02, green: 0.05, blue: 0.15)  // Darker space blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Location Info
                    locationInfoView
                    
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Statistics Cards
                    statisticsCards
                    
                    // Precipitation Chart
                    precipitationChart
                    
                    // Rainy Days Visualization
                    if showingRainyDays {
                        rainyDaysVisualization
                    }
                    
                    // Data Table
                    dataTableSection
                }
                .padding()
            }
        }
        .onAppear {
            if let coordinate = viewModel.selectedCoordinate {
                hydrologyManager.fetchRealPrecipitationData(for: coordinate, days: 30)
                resolvePlaceNameIfNeeded(for: coordinate)
            } else {
                // Default to Moscow if no location selected
                let moscowCoordinate = CLLocationCoordinate2D(latitude: 55.75, longitude: 37.62)
                hydrologyManager.fetchRealPrecipitationData(for: moscowCoordinate, days: 30)
                resolvePlaceNameIfNeeded(for: moscowCoordinate)
            }
        }
        .onChange(of: viewModel.selectedCoordinate) { newCoordinate in
            if let coordinate = newCoordinate {
                hydrologyManager.fetchRealPrecipitationData(for: coordinate, days: selectedTimeRange.days)
                resolvePlaceNameIfNeeded(for: coordinate)
            }
        }
        .onChange(of: selectedTimeRange) { newRange in
            if let coordinate = viewModel.selectedCoordinate {
                hydrologyManager.fetchRealPrecipitationData(for: coordinate, days: newRange.days)
                if let coordinate = viewModel.selectedCoordinate { resolvePlaceNameIfNeeded(for: coordinate) }
            } else {
                let moscowCoordinate = CLLocationCoordinate2D(latitude: 55.75, longitude: 37.62)
                hydrologyManager.fetchRealPrecipitationData(for: moscowCoordinate, days: newRange.days)
                resolvePlaceNameIfNeeded(for: moscowCoordinate)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "cloud.rain.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("NASA Precipitation Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Real-time precipitation monitoring and analysis")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Location Info View
    private var locationInfoView: some View {
        HStack {
            Image(systemName: "location.fill")
                .font(.title3)
                .foregroundColor(.cyan)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(getLocationName())
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(getLocationSecondaryLine())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                showingRainyDays.toggle()
            }) {
                Image(systemName: showingRainyDays ? "eye.fill" : "eye.slash.fill")
                    .font(.title3)
                    .foregroundColor(.cyan)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Time Range Selector
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Range")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        selectedTimeRange = range
                    }) {
                        Text(range.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedTimeRange == range ? Color.blue : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(selectedTimeRange == range ? .white : .gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Statistics Cards
    private var statisticsCards: some View {
        HStack(spacing: 12) {
            StatisticCard(
                title: "Total Rain",
                value: String(format: "%.1f mm", totalPrecipitation),
                icon: "cloud.rain.fill",
                color: .blue
            )
            
            StatisticCard(
                title: "Rainy Days",
                value: "\(rainyDaysCount)",
                icon: "calendar",
                color: .cyan
            )
            
            StatisticCard(
                title: "Avg Daily",
                value: String(format: "%.1f mm", averageDailyPrecipitation),
                icon: "chart.bar.fill",
                color: .green
            )
        }
    }
    
    // MARK: - Precipitation Chart
    private var precipitationChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Precipitation Over Time")
                .font(.headline)
                .foregroundColor(.white)
            
            if hydrologyManager.isLoading {
                ProgressView()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(filteredPrecipitationData) { data in
                    BarMark(
                        x: .value("Date", data.date),
                        y: .value("Precipitation", data.precipitation)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.8), .cyan.opacity(0.6)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 5)) { value in
                        AxisGridLine()
                            .foregroundStyle(.gray.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(.gray.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Rainy Days Visualization
    private var rainyDaysVisualization: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rainy Days Analysis")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(filteredRainyDays) { day in
                    RainyDayCard(rainyDay: day)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Data Table Section
    private var dataTableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Precipitation Data")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(filteredPrecipitationData.prefix(10))) { data in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatDate(data.date))
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Text(String(format: "%.1f mm", data.precipitation))
                                .font(.headline)
                                .foregroundColor(data.precipitation > 0 ? .blue : .gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: data.precipitation > 0 ? "cloud.rain.fill" : "sun.max.fill")
                            .font(.title3)
                            .foregroundColor(data.precipitation > 0 ? .blue : .yellow)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private var filteredPrecipitationData: [PrecipitationDataPoint] {
        Array(hydrologyManager.precipitationData.prefix(selectedTimeRange.days))
    }
    
    private var filteredRainyDays: [RainyDay] {
        Array(hydrologyManager.rainyDays.prefix(selectedTimeRange.days))
    }
    
    private var totalPrecipitation: Double {
        filteredPrecipitationData.reduce(0) { $0 + $1.precipitation }
    }
    
    private var rainyDaysCount: Int {
        filteredRainyDays.filter { $0.isRainy }.count
    }
    
    private var averageDailyPrecipitation: Double {
        guard !filteredPrecipitationData.isEmpty else { return 0 }
        return totalPrecipitation / Double(filteredPrecipitationData.count)
    }
    
    private func getLocationName() -> String {
        if let coordinate = viewModel.selectedCoordinate {
            if coordinate.latitude == 55.75 && coordinate.longitude == 37.62 {
                return "Moscow, Russia"
            } else {
                return "Selected Location"
            }
        } else {
            return "Moscow, Russia"
        }
    }
    
    private func getLocationSecondaryLine() -> String {
        if let name = viewModel.selectedCityName ?? resolvedPlaceName {
            return name
        }
        if let coordinate = viewModel.selectedCoordinate {
            return String(format: "%.2f°N, %.2f°E", coordinate.latitude, coordinate.longitude)
        }
        return "55.75°N, 37.62°E"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}

// MARK: - Reverse Geocoding
extension PrecipitationForecastView {
    private func resolvePlaceNameIfNeeded(for coordinate: CLLocationCoordinate2D) {
        if viewModel.selectedCityName != nil { return }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            if let placemark = placemarks?.first {
                let components = [placemark.locality, placemark.subLocality, placemark.administrativeArea, placemark.country].compactMap { $0 }
                if let best = components.first {
                    resolvedPlaceName = best
                } else if let name = placemark.name {
                    resolvedPlaceName = name
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct RainyDayCard: View {
    let rainyDay: RainyDay
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formatDay(rainyDay.date))
                .font(.caption2)
                .foregroundColor(.white)
            
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(rainyDay.isRainy ? getIntensityColor() : Color.gray.opacity(0.3))
                    .frame(height: 20)
                
                if rainyDay.isRainy {
                    Image(systemName: "cloud.rain.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "sun.max.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            
            if rainyDay.isRainy {
                Text(String(format: "%.1f", rainyDay.precipitation))
                    .font(.caption2)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    private func getIntensityColor() -> Color {
        switch rainyDay.intensity {
        case .none: return .gray
        case .light: return .blue
        case .moderate: return .cyan
        case .heavy: return .orange
        case .extreme: return .red
        }
    }
}

#Preview {
    PrecipitationForecastView(viewModel: AppViewModel())
}
