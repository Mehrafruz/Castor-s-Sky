// RainViewerLayerManager.swift
import MapKit
import Combine

class RainViewerLayerManager: ObservableObject {
    @Published var currentLayer: RainViewerOverlay.LayerType = .radar
    @Published var availableTimestamps: [Date] = []
    @Published var selectedTimestamp: Date = Date()
    
    private weak var mapView: MKMapView?
    private var currentOverlay: RainViewerOverlay?
    
    init() {
        generateTimestamps()
    }
    
    func setMapView(_ mapView: MKMapView) {
        self.mapView = mapView
        updateOverlay()
    }
    
    func updateLayer(_ layer: RainViewerOverlay.LayerType) {
        currentLayer = layer
        updateOverlay()
    }
    
    func updateTimestamp(_ timestamp: Date) {
        selectedTimestamp = timestamp
        updateOverlay()
    }
    
    func getTimestampDescription(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    private func generateTimestamps() {
        let now = Date()
        var times: [Date] = []
        // Последние 12 отметок с шагом 10 минут
        for i in 0..<12 {
            if let time = Calendar.current.date(byAdding: .minute, value: -(i * 10), to: now) {
                times.append(time)
            }
        }
        availableTimestamps = times
        selectedTimestamp = times.first ?? now
    }
    
    private func updateOverlay() {
        guard let mapView = mapView else { return }
        
        if let currentOverlay = currentOverlay {
            mapView.removeOverlay(currentOverlay)
        }
        
        let overlay = RainViewerOverlay(layerType: currentLayer, timestamp: selectedTimestamp)
        mapView.addOverlay(overlay, level: .aboveLabels)
        currentOverlay = overlay
    }
}
