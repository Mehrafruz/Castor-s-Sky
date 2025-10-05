//
//  WeatherOverlay.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import MapKit
import Combine

class WeatherOverlay: MKTileOverlay {
    
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
        
        print("🌤️ Loading weather tile: \(url)")
        print("🌤️ Layer: \(layerType.rawValue), Z: \(path.z), X: \(path.x), Y: \(path.y)")
        
        // Добавляем User-Agent для Open-Meteo API
        var request = URLRequest(url: url)
        request.setValue("CastorSky/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("image/png", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Weather Tile Error: \(error.localizedDescription)")
                    result(nil, error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Weather Tile: Invalid response")
                    result(nil, NSError(domain: "WeatherOverlay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                    return
                }
                
                print("🌤️ Weather Tile Response: \(httpResponse.statusCode) for \(url)")
                
                if httpResponse.statusCode == 404 {
                    // Тайл не найден - это нормально для некоторых регионов
                    print("⚠️ Weather Tile: 404 - Tile not found")
                    result(nil, nil)
                    return
                }
                
                if httpResponse.statusCode == 200, let data = data, !data.isEmpty {
                    print("✅ Weather Tile: Successfully loaded tile (\(data.count) bytes)")
                    result(data, nil)
                } else {
                    print("❌ Weather Tile: Failed to load - Status: \(httpResponse.statusCode)")
                    result(nil, nil)
                }
            }
        }.resume()
    }
}

// MARK: - Weather Layer Manager
class WeatherLayerManager: ObservableObject {
    @Published var currentLayer: WeatherOverlay.LayerType = .precipitation
    @Published var isLayerVisible: Bool = true
    
    private var currentOverlay: WeatherOverlay?
    private weak var mapView: MKMapView?
    
    func setMapView(_ mapView: MKMapView) {
        self.mapView = mapView
        updateOverlay()
    }
    
    func updateLayer(_ layerType: WeatherOverlay.LayerType) {
        currentLayer = layerType
        updateOverlay()
    }
    
    func toggleLayerVisibility() {
        isLayerVisible.toggle()
        updateOverlay()
    }
    
    private func updateOverlay() {
        guard let mapView = mapView else { 
            print("❌ WeatherLayerManager: mapView is nil")
            return 
        }
        
        print("🔄 WeatherLayerManager: Updating overlay - Layer: \(currentLayer.rawValue), Visible: \(isLayerVisible)")
        
        // Удаляем старый overlay
        if let currentOverlay = currentOverlay {
            print("🗑️ WeatherLayerManager: Removing old overlay")
            mapView.removeOverlay(currentOverlay)
        }
        
        // Добавляем новый overlay если слой видимый
        if isLayerVisible {
            let newOverlay = WeatherOverlay(layerType: currentLayer)
            print("➕ WeatherLayerManager: Adding new overlay for \(currentLayer.rawValue)")
            mapView.addOverlay(newOverlay, level: .aboveLabels)
            self.currentOverlay = newOverlay
        } else {
            print("👁️ WeatherLayerManager: Layer hidden")
            self.currentOverlay = nil
        }
    }
}

// MARK: - Weather Overlay Renderer
class WeatherOverlayRenderer: MKTileOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? WeatherOverlay else { return }
        
        // Устанавливаем прозрачность и режим смешивания для лучшей видимости
        switch overlay.layerType {
        case .precipitation:
            context.setAlpha(1.0) // Максимальная непрозрачность для осадков
            context.setBlendMode(.normal) // Нормальное смешивание
        case .temperature:
            context.setAlpha(0.8) // Хорошая видимость для температуры
            context.setBlendMode(.multiply) // Умножение для лучшего контраста
        case .cloudcover:
            context.setAlpha(0.7) // Средняя прозрачность для облачности
            context.setBlendMode(.overlay) // Наложение для мягкого эффекта
        case .windspeed:
            context.setAlpha(0.9) // Хорошая видимость для ветра
            context.setBlendMode(.normal)
        case .pressure:
            context.setAlpha(0.8) // Хорошая видимость для давления
            context.setBlendMode(.multiply)
        }
        
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }
}
