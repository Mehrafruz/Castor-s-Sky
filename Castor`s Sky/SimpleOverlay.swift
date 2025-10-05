//
//  SimpleOverlay.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import MapKit
import UIKit

class SimpleOverlay: MKTileOverlay {
    
    enum LayerType: String, CaseIterable {
        case clouds = "clouds"
        case precipitation = "precipitation"
        case temperature = "temperature"
        
        var displayName: String {
            switch self {
            case .clouds:
                return "Облачность"
            case .precipitation:
                return "Осадки"
            case .temperature:
                return "Температура"
            }
        }
        
        var color: UIColor {
            switch self {
            case .clouds:
                return UIColor.white.withAlphaComponent(0.3)
            case .precipitation:
                return UIColor.blue.withAlphaComponent(0.4)
            case .temperature:
                return UIColor.red.withAlphaComponent(0.3)
            }
        }
    }
    
    private let layerType: LayerType
    
    init(layerType: LayerType) {
        self.layerType = layerType
        super.init(urlTemplate: "")
        self.canReplaceMapContent = false
        self.minimumZ = 1
        self.maximumZ = 8
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        // Создаем простой цветной тайл
        let tileSize = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: tileSize)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Создаем градиент в зависимости от типа слоя
            let colors = layerType.color.cgColor
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), 
                                    colors: [colors, colors.copy(alpha: 0.1)!] as CFArray, 
                                    locations: [0.0, 1.0])
            
            if let gradient = gradient {
                cgContext.drawLinearGradient(gradient, 
                                          start: CGPoint(x: 0, y: 0), 
                                          end: CGPoint(x: tileSize.width, y: tileSize.height), 
                                          options: [])
            }
            
            // Добавляем паттерн в зависимости от типа
            switch layerType {
            case .clouds:
                drawCloudPattern(in: cgContext, size: tileSize)
            case .precipitation:
                drawRainPattern(in: cgContext, size: tileSize)
            case .temperature:
                drawTemperaturePattern(in: cgContext, size: tileSize)
            }
        }
        
        if let data = image.pngData() {
            result(data, nil)
        } else {
            result(nil, NSError(domain: "SimpleOverlay", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create tile"]))
        }
    }
    
    private func drawCloudPattern(in context: CGContext, size: CGSize) {
        context.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
        
        // Рисуем простые облака
        for _ in 0..<5 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let radius = CGFloat.random(in: 20...40)
            
            context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
    }
    
    private func drawRainPattern(in context: CGContext, size: CGSize) {
        context.setStrokeColor(UIColor.blue.withAlphaComponent(0.6).cgColor)
        context.setLineWidth(1.0)
        
        // Рисуем дождь
        for _ in 0..<20 {
            let startX = CGFloat.random(in: 0...size.width)
            let startY = CGFloat.random(in: 0...size.height)
            let endX = startX + CGFloat.random(in: -5...5)
            let endY = startY + CGFloat.random(in: 10...20)
            
            context.move(to: CGPoint(x: startX, y: startY))
            context.addLine(to: CGPoint(x: endX, y: endY))
            context.strokePath()
        }
    }
    
    private func drawTemperaturePattern(in context: CGContext, size: CGSize) {
        context.setFillColor(UIColor.red.withAlphaComponent(0.3).cgColor)
        
        // Рисуем тепловые зоны
        for _ in 0..<3 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let radius = CGFloat.random(in: 30...60)
            
            context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
    }
}

// MARK: - Simple Overlay Renderer
class SimpleOverlayRenderer: MKTileOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? SimpleOverlay else { return }
        
        // Устанавливаем прозрачность
        context.setAlpha(0.7)
        
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }
}

