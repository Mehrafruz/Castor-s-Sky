//
//  NASAOverlay.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import MapKit
import Combine

class NASAOverlay: MKTileOverlay {
    
    enum LayerType: String, CaseIterable {
        case cloudMask = "MODIS_Terra_Cloud_Fraction_Day"
        case precipitation = "IMERG_Precipitation_Rate"
        case temperature = "AIRS_L3_Temperature_850hPa_Daily_Day"
        
        var displayName: String {
            switch self {
            case .cloudMask:
                return "Облачность"
            case .precipitation:
                return "Осадки"
            case .temperature:
                return "Температура"
            }
        }
    }
    
    private let layerType: LayerType
    private let date: Date
    
    init(layerType: LayerType, date: Date = Date()) {
        self.layerType = layerType
        self.date = date
        super.init(urlTemplate: "")
        self.canReplaceMapContent = false
        self.minimumZ = 1
        self.maximumZ = 8
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Используем публичный WMTS endpoint NASA
        let baseURL = "https://gibs.earthdata.nasa.gov/wmts/epsg3857/best"
        let urlString = "\(baseURL)/\(layerType.rawValue)/default/\(dateString)/250m/\(path.z)/\(path.y)/\(path.x).png"
        
        return URL(string: urlString)!
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let url = self.url(forTilePath: path)
        
        // Добавляем User-Agent для NASA API
        var request = URLRequest(url: url)
        request.setValue("CastorSky/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("NASA Tile Error: \(error.localizedDescription)")
                result(nil, error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("NASA Tile: Invalid response")
                result(nil, NSError(domain: "NASAOverlay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                return
            }
            
            print("NASA Tile Response: \(httpResponse.statusCode) for \(url)")
            
            if httpResponse.statusCode == 404 {
                // Тайл не найден - это нормально для некоторых дат/регионов
                print("NASA Tile: 404 - Tile not found")
                result(nil, nil)
                return
            }
            
            if httpResponse.statusCode == 200, let data = data, !data.isEmpty {
                print("NASA Tile: Successfully loaded tile")
                result(data, nil)
            } else {
                print("NASA Tile: Empty or invalid data")
                result(nil, nil)
            }
        }.resume()
    }
}

// MARK: - NASA Layer Manager
class NASALayerManager: ObservableObject {
    @Published var currentLayer: NASAOverlay.LayerType = .cloudMask
    @Published var selectedDate: Date = Date()
    @Published var isLayerVisible: Bool = true
    
    private var currentOverlay: NASAOverlay?
    private weak var mapView: MKMapView?
    
    func setMapView(_ mapView: MKMapView) {
        self.mapView = mapView
        updateOverlay()
    }
    
    func updateLayer(_ layerType: NASAOverlay.LayerType) {
        currentLayer = layerType
        updateOverlay()
    }
    
    func updateDate(_ date: Date) {
        selectedDate = date
        updateOverlay()
    }
    
    func toggleLayerVisibility() {
        isLayerVisible.toggle()
        updateOverlay()
    }
    
    private func updateOverlay() {
        guard let mapView = mapView else { return }
        
        // Удаляем старый overlay
        if let currentOverlay = currentOverlay {
            mapView.removeOverlay(currentOverlay)
        }
        
        // Добавляем новый overlay если слой видимый
        if isLayerVisible {
            let newOverlay = NASAOverlay(layerType: currentLayer, date: selectedDate)
            mapView.addOverlay(newOverlay, level: .aboveLabels)
            self.currentOverlay = newOverlay
        } else {
            self.currentOverlay = nil
        }
    }
}

// MARK: - NASA Overlay Renderer
class NASAOverlayRenderer: MKTileOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? NASAOverlay else { return }
        
        // Устанавливаем прозрачность для лучшей видимости базовой карты
        context.setAlpha(0.7)
        
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }
}
