//
//  WeatherMapView.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI
import MapKit

struct WeatherMapView: View {
    @StateObject private var enhancedWeatherManager = EnhancedWeatherLayerManager()
    @ObservedObject var viewModel: AppViewModel
    @State private var mapView: MKMapView?
    @State private var showingLayerPicker = false
    @State private var showingWeatherCard = false
    @State private var showingCitySearch = false
    
    var body: some View {
        ZStack {
            // Space-themed background
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.11, blue: 0.23), Color(red: 0.02, green: 0.05, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main Map (English Language)
            EnglishMapView(
                selectedCoordinate: $viewModel.selectedCoordinate,
                showAnnotation: $viewModel.showAnnotation,
                rainViewerManager: RainViewerLayerManager(),
                weatherManager: WeatherLayerManager(),
                enhancedWeatherManager: enhancedWeatherManager,
                onTap: { coordinate in
                    viewModel.selectCoordinate(coordinate)
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingWeatherCard = true
                    }
                }
            )
            .onAppear {
                setupMapView()
            }
            
            // Top Header
            VStack {
                HStack {
                    // NASA-style logo
                    HStack(spacing: 8) {
                        Image(systemName: "cloud.rain.fill")
                            .font(.title2)
                            .foregroundColor(.cyan)
                        Text("Castor's Sky")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Layer button
                    Button(action: { showingLayerPicker = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: enhancedWeatherManager.currentLayer.icon)
                                .font(.system(size: 16, weight: .medium))
                            Text(enhancedWeatherManager.currentLayer.displayName)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                    }

                    // Right-side vertical controls: Search above Settings
                    VStack(spacing: 12) {
                        // Search button (top)
                        Button(action: { showingCitySearch = true }) {
                            Image(systemName: "magnifyingglass")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(.cyan.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }

                        // Settings button (bottom)
                        Button(action: {}) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Circle()
                                                .stroke(.cyan.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            
            // Weather Card (Bottom Sheet)
            if showingWeatherCard, let coordinate = viewModel.selectedCoordinate {
                WeatherCardView(
                    coordinate: coordinate,
                    cityName: viewModel.selectedCityName,
                    weatherManager: WeatherLayerManager(),
                    isPresented: $showingWeatherCard
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showingLayerPicker) {
            EnhancedWeatherLayerPickerView { layer in
                enhancedWeatherManager.updateLayer(layer)
            }
        }
        .sheet(isPresented: $showingCitySearch) {
            CitySearchView(
                isPresented: $showingCitySearch,
                selectedCoordinate: $viewModel.selectedCoordinate,
                selectedCityName: $viewModel.selectedCityName
            )
        }
    }
    
    private func setupMapView() {
        // Setup will be handled in MapViewRepresentable
    }
}

// MARK: - Enhanced Weather Layer Picker View
struct EnhancedWeatherLayerPickerView: View {
    let onLayerSelected: (EnhancedWeatherOverlay.LayerType) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(EnhancedWeatherOverlay.LayerType.allCases, id: \.self) { layer in
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
    WeatherMapView(
        viewModel: AppViewModel()
    )
}
