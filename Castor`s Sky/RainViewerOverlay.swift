// RainViewerOverlay.swift
import MapKit
import UIKit

class RainViewerOverlay: MKTileOverlay {
    enum LayerType: CaseIterable {
        case radar
        case satellite
        case temperature
        
        var displayName: String {
            switch self {
            case .radar: return "Радар"
            case .satellite: return "Спутник"
            case .temperature: return "Температура"
            }
        }
        
        var description: String {
            switch self {
            case .radar: return "Радарные осадки (демо)"
            case .satellite: return "Спутниковые снимки (демо)"
            case .temperature: return "Температура поверхности (демо)"
            }
        }
        
        var color: UIColor {
            switch self {
            case .radar: return UIColor.systemBlue
            case .satellite: return UIColor.systemGray
            case .temperature: return UIColor.systemRed
            }
        }
    }
    
    let layerType: LayerType
    let timestamp: Date
    
    init(layerType: LayerType, timestamp: Date) {
        self.layerType = layerType
        self.timestamp = timestamp
        super.init(urlTemplate: "")
        canReplaceMapContent = false
        minimumZ = 1
        maximumZ = 12
        tileSize = CGSize(width: 256, height: 256)
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        // Генерируем простой визуальный тайл для демонстрации
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let ctx = context.cgContext
            
            // Фон
            ctx.setFillColor(layerType.color.withAlphaComponent(0.25).cgColor)
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Диагональный узор
            ctx.setStrokeColor(layerType.color.withAlphaComponent(0.6).cgColor)
            ctx.setLineWidth(1.0)
            let step: CGFloat = 24
            for i in stride(from: -size.height, through: size.width, by: step) {
                ctx.move(to: CGPoint(x: i, y: 0))
                ctx.addLine(to: CGPoint(x: i + size.height, y: size.height))
            }
            ctx.strokePath()
            
            // Легкая вариативность от тайла
            let seed = CGFloat((path.x ^ path.y ^ path.z) % 10)
            ctx.setFillColor(layerType.color.withAlphaComponent(0.15).cgColor)
            ctx.fillEllipse(in: CGRect(x: 20 + seed, y: 20 + seed, width: 60, height: 60))
        }
        
        result(image.pngData(), nil)
    }
}

class RainViewerOverlayRenderer: MKTileOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        context.setAlpha(0.6)
        super.draw(mapRect, zoomScale: zoomScale, in: context)
    }
}
