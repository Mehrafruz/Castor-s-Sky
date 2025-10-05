//
//  ContentView.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var weatherManager = WeatherLayerManager()
    @State private var mapView: MKMapView?
    @State private var showingLayerPicker = false
    @State private var showingDatePicker = false
    @State private var currentOverlay: WeatherOverlay?
    
    var body: some View {
        ZStack {
            // Основная карта
            MapViewRepresentable(
                selectedCoordinate: $viewModel.selectedCoordinate,
                showAnnotation: $viewModel.showAnnotation,
                rainViewerManager: RainViewerLayerManager(),
                weatherManager: weatherManager,
                onTap: { coordinate in
                    viewModel.selectCoordinate(coordinate)
                }
            )
            .onAppear {
                setupMapView()
            }
            
            // Панель управления сверху
            VStack {
                HStack {
                    Spacer()
                    
                    // Кнопка выбора слоя
                    Button(action: { showingLayerPicker = true }) {
                        VStack(spacing: 4) {
                            Image(systemName: weatherManager.currentLayer.icon)
                                .font(.title2)
                            Text(weatherManager.currentLayer.displayName)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    // Кнопка быстрого переключения слоев
                    Button(action: { 
                        cycleWeatherLayer()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                            Text("Next")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    
                    // Кнопка видимости слоя
                    Button(action: { 
                        weatherManager.toggleLayerVisibility()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: weatherManager.isLayerVisible ? "eye.fill" : "eye.slash.fill")
                                .font(.title2)
                            Text("Layer")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(weatherManager.isLayerVisible ? Color.orange.opacity(0.8) : Color.gray.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Панель информации снизу
            VStack {
                Spacer()
                
                // Информация о текущем слое
                if weatherManager.isLayerVisible {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: weatherManager.currentLayer.icon)
                                .foregroundColor(.blue)
                            Text("Active Layer: \(weatherManager.currentLayer.displayName)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        Text(weatherManager.currentLayer.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                }
                
                if let coordinate = viewModel.selectedCoordinate {
                    VStack(spacing: 8) {
                        Text("Selected Point")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(viewModel.selectedCoordinateDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Clear Selection") {
                            viewModel.clearSelection()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingLayerPicker) {
            WeatherLayerPickerView { layer in
                weatherManager.updateLayer(layer)
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $viewModel.selectedDate) { date in
                viewModel.updateDate(date)
            }
        }
    }
    
    private func setupMapView() {
        // Настройка будет выполнена в MapViewRepresentable
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    private func cycleWeatherLayer() {
        let allLayers = WeatherOverlay.LayerType.allCases
        guard let currentIndex = allLayers.firstIndex(of: weatherManager.currentLayer) else { return }
        
        let nextIndex = (currentIndex + 1) % allLayers.count
        let nextLayer = allLayers[nextIndex]
        
        weatherManager.updateLayer(nextLayer)
        print("🔄 Switched to layer: \(nextLayer.displayName)")
    }
}

// MARK: - Layer Picker View
struct LayerPickerView: View {
    @Binding var selectedLayer: NASAOverlay.LayerType
    let onLayerSelected: (NASAOverlay.LayerType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(NASAOverlay.LayerType.allCases, id: \.self) { layer in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(layer.displayName)
                                .font(.headline)
                            Text(layer.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedLayer == layer {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLayer = layer
                        onLayerSelected(layer)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Выберите слой")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Date Picker View
struct DatePickerView: View {
    @Binding var selectedDate: Date
    let onDateSelected: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Выберите дату",
                    selection: $selectedDate,
                    in: Date.distantPast...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Выберите дату")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        onDateSelected(selectedDate)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - RainViewer Layer Picker View
struct RainViewerLayerPickerView: View {
    let onLayerSelected: (RainViewerOverlay.LayerType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(RainViewerOverlay.LayerType.allCases, id: \.self) { layer in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(layer.displayName)
                                .font(.headline)
                            Text(layer.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Иконка слоя
                        Image(systemName: layerIcon(for: layer))
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onLayerSelected(layer)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Выберите слой")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func layerIcon(for layer: RainViewerOverlay.LayerType) -> String {
        switch layer {
        case .radar:
            return "cloud.rain.fill"
        case .satellite:
            return "satellite.fill"
        case .temperature:
            return "thermometer"
        }
    }
}

// MARK: - Time Picker View
struct TimePickerView: View {
    @ObservedObject var rainViewerManager: RainViewerLayerManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Select Time")
                    .font(.headline)
                    .padding()
                
                List {
                    ForEach(rainViewerManager.availableTimestamps, id: \.self) { timestamp in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(rainViewerManager.getTimestampDescription(timestamp))
                                    .font(.headline)
                                Text("Radar Data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if timestamp == rainViewerManager.selectedTimestamp {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            rainViewerManager.updateTimestamp(timestamp)
                        }
                    }
                }
            }
            .navigationTitle("Data Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Weather Layer Picker View
struct WeatherLayerPickerView: View {
    let onLayerSelected: (WeatherOverlay.LayerType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(WeatherOverlay.LayerType.allCases, id: \.self) { layer in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(layer.displayName)
                                .font(.headline)
                            Text(layer.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Иконка слоя
                        Image(systemName: layer.icon)
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onLayerSelected(layer)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Select Weather Layer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
