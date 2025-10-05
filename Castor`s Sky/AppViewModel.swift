//
//  AppViewModel.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI
import MapKit
import Combine

class AppViewModel: ObservableObject {
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var selectedCityName: String?
    @Published var showAnnotation: Bool = false
    @Published var currentLayer: NASAOverlay.LayerType = .cloudMask
    @Published var selectedDate: Date = Date()
    @Published var isLayerVisible: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Автоматически скрываем аннотацию при смене слоя
        $currentLayer
            .sink { [weak self] _ in
                self?.showAnnotation = false
            }
            .store(in: &cancellables)
    }
    
    func selectCoordinate(_ coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        selectedCityName = nil // Clear city name when selecting by coordinates
        showAnnotation = true
    }
    
    func selectCity(_ coordinate: CLLocationCoordinate2D, cityName: String) {
        selectedCoordinate = coordinate
        selectedCityName = cityName
        showAnnotation = true
    }
    
    func clearSelection() {
        selectedCoordinate = nil
        selectedCityName = nil
        showAnnotation = false
    }
    
    func updateLayer(_ layer: NASAOverlay.LayerType) {
        currentLayer = layer
    }
    
    func updateDate(_ date: Date) {
        selectedDate = date
    }
    
    func toggleLayerVisibility() {
        isLayerVisible.toggle()
    }
    
    var selectedCoordinateDescription: String {
        guard let coordinate = selectedCoordinate else {
            return "No point selected"
        }
        return String(format: "%.4f°N, %.4f°E", coordinate.latitude, coordinate.longitude)
    }
}
