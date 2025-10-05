//
//  EnhancedWeatherOverlay.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import MapKit
import UIKit
import Combine

class EnhancedWeatherOverlay: MKTileOverlay {
    
    enum LayerType: String, CaseIterable {
        case precipitation = "precipitation_new"
        case temperature = "temp_new"
        case cloudcover = "clouds_new"
        case windspeed = "wind_new"
        case pressure = "pressure_new"
        
        var displayName: String {
            switch self {
            case .precipitation:
                return "Precipitation"
            case .temperature:
                return "Temperature"
            case .cloudcover:
                return "Cloud Cover"
            case .windspeed:
                return "Wind Speed"
            case .pressure:
                return "Pressure"
            }
        }
        
        var description: String {
            switch self {
            case .precipitation:
                return "Real-time precipitation data"
            case .temperature:
                return "Air temperature"
            case .cloudcover:
                return "Cloud coverage percentage"
            case .windspeed:
                return "Wind speed and direction"
            case .pressure:
                return "Atmospheric pressure"
            }
        }
        
        var icon: String {
            switch self {
            case .precipitation:
                return "cloud.rain.fill"
            case .temperature:
                return "thermometer"
            case .cloudcover:
                return "cloud.fill"
            case .windspeed:
                return "wind"
            case .pressure:
                return "barometer"
            }
        }
    }
    
    fileprivate let layerType: LayerType
    
    init(layerType: LayerType) {
        self.layerType = layerType
        super.init(urlTemplate: "")
        self.canReplaceMapContent = false
        self.minimumZ = 1
        self.maximumZ = 10
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        // Используем OpenWeatherMap API с реальным ключом
        let baseURL = "https://tile.openweathermap.org/map"
        let apiKey = "5bec64a73f11f243090191161ccf6544"
        let urlString = "\(baseURL)/\(layerType.rawValue)/\(path.z)/\(path.x)/\(path.y).png?appid=\(apiKey)"
        
        return URL(string: urlString)!
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let url = self.url(forTilePath: path)
        
        print("🌤️ Loading enhanced weather tile: \(url)")
        print("🌤️ Layer: \(layerType.rawValue), Z: \(path.z), X: \(path.x), Y: \(path.y)")
        
        // Добавляем User-Agent для OpenWeatherMap API
        var request = URLRequest(url: url)
        request.setValue("CastorSky/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("image/png", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Enhanced Weather Tile Error: \(error.localizedDescription)")
                    result(nil, error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Enhanced Weather Tile: Invalid response")
                    result(nil, NSError(domain: "EnhancedWeatherOverlay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                    return
                }
                
                print("🌤️ Enhanced Weather Tile Response: \(httpResponse.statusCode) for \(url)")
                
                if httpResponse.statusCode == 404 {
                    print("⚠️ Enhanced Weather Tile: 404 - Tile not found")
                    result(nil, nil)
                    return
                }
                
                if httpResponse.statusCode == 200, let data = data, !data.isEmpty {
                    print("✅ Enhanced Weather Tile: Successfully loaded tile (\(data.count) bytes)")
                    result(data, nil)
                } else {
                    print("❌ Enhanced Weather Tile: Failed to load - Status: \(httpResponse.statusCode)")
                    result(nil, nil)
                }
            }
        }.resume()
    }
}

// MARK: - Enhanced Weather Overlay Renderer
class EnhancedWeatherOverlayRenderer: MKTileOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? EnhancedWeatherOverlay else { return }
        
        // Улучшенная видимость для разных типов слоев
        switch overlay.layerType {
        case .precipitation:
            // Максимальная видимость для осадков
            context.setAlpha(1.0)
            context.setBlendMode(.normal)
            
            // Добавляем дополнительное усиление контраста
            context.setShadow(offset: CGSize(width: 0, height: 0), blur: 2, color: UIColor.cyan.cgColor)
            
        case .temperature:
            context.setAlpha(0.9)
            context.setBlendMode(.multiply)
            
        case .cloudcover:
            context.setAlpha(0.8)
            context.setBlendMode(.overlay)
            
        case .windspeed:
            context.setAlpha(0.95)
            context.setBlendMode(.normal)
            
        case .pressure:
            context.setAlpha(0.85)
            context.setBlendMode(.multiply)
        }
        
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }
}

// MARK: - Enhanced Weather Layer Manager
class EnhancedWeatherLayerManager: ObservableObject {
    @Published var currentLayer: EnhancedWeatherOverlay.LayerType = .precipitation
    @Published var isLayerVisible: Bool = true
    
    private var currentOverlay: EnhancedWeatherOverlay?
    private weak var mapView: MKMapView?
    
    func setMapView(_ mapView: MKMapView) {
        self.mapView = mapView
        updateOverlay()
    }
    
    func updateLayer(_ layerType: EnhancedWeatherOverlay.LayerType) {
        currentLayer = layerType
        updateOverlay()
    }
    
    func toggleLayerVisibility() {
        isLayerVisible.toggle()
        updateOverlay()
    }
    
    private func updateOverlay() {
        guard let mapView = mapView else { 
            print("❌ EnhancedWeatherLayerManager: mapView is nil")
            return 
        }
        
        print("🔄 EnhancedWeatherLayerManager: Updating overlay - Layer: \(currentLayer.rawValue), Visible: \(isLayerVisible)")
        
        // Удаляем старый overlay
        if let currentOverlay = currentOverlay {
            print("🗑️ EnhancedWeatherLayerManager: Removing old overlay")
            mapView.removeOverlay(currentOverlay)
        }
        
        // Добавляем новый overlay если слой видимый
        if isLayerVisible {
            let newOverlay = EnhancedWeatherOverlay(layerType: currentLayer)
            print("➕ EnhancedWeatherLayerManager: Adding new enhanced overlay for \(currentLayer.rawValue)")
            mapView.addOverlay(newOverlay, level: .aboveLabels)
            self.currentOverlay = newOverlay
        } else {
            print("👁️ EnhancedWeatherLayerManager: Layer hidden")
            self.currentOverlay = nil
        }
    }
}


