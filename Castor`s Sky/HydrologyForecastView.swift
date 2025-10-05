//
//  HydrologyForecastView.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI
import Charts
import MapKit
import CoreLocation

// Make CLLocationCoordinate2D Equatable so Optional<CLLocationCoordinate2D> becomes Equatable,
// allowing it to be used with SwiftUI's onChange(of:)
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct HydrologyForecastView: View {
    @StateObject private var hydrologyManager = NASAHydrologyManager()
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedDataType: DataType = .precipitation
    
    // Временно: сюда можно вставить ваш EDL Bearer Token для теста
    private let edlToken: String? = nil // "PASTE_YOUR_EARTHDATA_BEARER_TOKEN_HERE"
    
    enum TimeRange: String, CaseIterable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        
        var hours: Int {
            switch self {
            case .day: return 24
            case .week: return 168
            case .month: return 720
            }
        }
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    enum DataType: String, CaseIterable {
        case precipitation = "Precipitation"
        case soilMoisture = "Soil Moisture"
        case temperature = "Temperature"
        case humidity = "Humidity"
        case pressure = "Pressure"
        
        var icon: String {
            switch self {
            case .precipitation: return "cloud.rain.fill"
            case .soilMoisture: return "drop.fill"
            case .temperature: return "thermometer"
            case .humidity: return "humidity"
            case .pressure: return "barometer"
            }
        }
        
        var unit: String {
            switch self {
            case .precipitation: return "mm/h"
            case .soilMoisture: return "m³/m³"
            case .temperature: return "°C"
            case .humidity: return "%"
            case .pressure: return "hPa"
            }
        }
        
        var color: Color {
            switch self {
            case .precipitation: return .blue
            case .soilMoisture: return .brown
            case .temperature: return .orange
            case .humidity: return .cyan
            case .pressure: return .purple
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Space-themed background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.11, blue: 0.23),
                    Color(red: 0.02, green: 0.05, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Ошибки NASA/EDL
                    if let error = hydrologyManager.errorMessage, !error.isEmpty {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                    
                    // Data Type Selector
                    dataTypeSelector
                    
                    // Time Range Selector
                    timeRangeSelector
                    
                    // Current Conditions Card
                    if let latestData = hydrologyManager.hydrologyData.first {
                        currentConditionsCard(data: latestData)
                    }
                    
                    // Chart Section
                    chartSection
                    
                    // Data Table
                    dataTableSection
                }
                .padding()
            }
        }
        .onAppear {
            // Передадим токен, если он есть
            hydrologyManager.setEDLBearerToken(edlToken)
            
            // Координата: выбранная или дефолт (Москва) для теста
            let coord = viewModel.selectedCoordinate ?? CLLocationCoordinate2D(latitude: 55.75, longitude: 37.62)
            hydrologyManager.fetchHydrologyData(for: coord, days: selectedTimeRange.days)
        }
        .onChange(of: viewModel.selectedCoordinate) { newCoordinate in
            if let coordinate = newCoordinate {
                hydrologyManager.fetchHydrologyData(for: coordinate, days: selectedTimeRange.days)
            }
        }
        .onChange(of: selectedTimeRange) { newRange in
            let coord = viewModel.selectedCoordinate ?? CLLocationCoordinate2D(latitude: 55.75, longitude: 37.62)
            hydrologyManager.fetchHydrologyData(for: coord, days: newRange.days)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text("NASA Hydrology Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Real-time hydrological monitoring")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Data Type Selector
    private var dataTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Type")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DataType.allCases, id: \.self) { dataType in
                        Button(action: {
                            selectedDataType = dataType
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: dataType.icon)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text(dataType.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedDataType == dataType ? dataType.color : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(selectedDataType == dataType ? .white : .gray)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
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
                                    .fill(selectedTimeRange == range ? Color.cyan : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(selectedTimeRange == range ? .white : .gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Current Conditions Card
    private func currentConditionsCard(data: NASAHydrologyData) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: selectedDataType.icon)
                    .font(.title2)
                    .foregroundColor(selectedDataType.color)
                
                Text("Current Conditions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedDataType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(formatValue(for: data))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(selectedDataType.unit)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(data.formattedTimestamp)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selectedDataType.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedDataType.rawValue) Over Time")
                .font(.headline)
                .foregroundColor(.white)
            
            if hydrologyManager.isLoading {
                ProgressView()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(filteredData) { data in
                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value(selectedDataType.rawValue, getValue(for: data))
                    )
                    .foregroundStyle(selectedDataType.color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Time", data.timestamp),
                        y: .value(selectedDataType.rawValue, getValue(for: data))
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [selectedDataType.color.opacity(0.3), selectedDataType.color.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { value in
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
    
    // MARK: - Data Table Section
    private var dataTableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Data")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(filteredData.prefix(10))) { data in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(data.formattedTimestamp)
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Text(formatValue(for: data))
                                .font(.headline)
                                .foregroundColor(selectedDataType.color)
                        }
                        
                        Spacer()
                        
                        Image(systemName: selectedDataType.icon)
                            .font(.title3)
                            .foregroundColor(selectedDataType.color)
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
    private var filteredData: [NASAHydrologyData] {
        let maxHours = selectedTimeRange.hours
        return Array(hydrologyManager.hydrologyData.prefix(maxHours))
    }
    
    private func getValue(for data: NASAHydrologyData) -> Double {
        switch selectedDataType {
        case .precipitation:
            return data.precipitation ?? 0
        case .soilMoisture:
            return data.soilMoisture ?? 0
        case .temperature:
            return data.temperature ?? 0
        case .humidity:
            return data.humidity ?? 0
        case .pressure:
            return data.pressure ?? 0
        }
    }
    
    private func formatValue(for data: NASAHydrologyData) -> String {
        let value = getValue(for: data)
        switch selectedDataType {
        case .precipitation:
            return String(format: "%.1f", value)
        case .soilMoisture:
            return String(format: "%.3f", value)
        case .temperature:
            return String(format: "%.1f", value)
        case .humidity:
            return String(format: "%.0f", value)
        case .pressure:
            return String(format: "%.0f", value)
        }
    }
}

#Preview {
    HydrologyForecastView(viewModel: AppViewModel())
}


