//
//  MapViewRepresentable.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var showAnnotation: Bool
    @State private var nasaOverlay: MKOverlay?
    @ObservedObject var rainViewerManager: RainViewerLayerManager
    @ObservedObject var weatherManager: WeatherLayerManager
    let onTap: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Настройка начального региона (мир) с космической темой
        let worldRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 120.0, longitudeDelta: 120.0)
        )
        mapView.setRegion(worldRegion, animated: false)
        
        // Настройка стиля карты для космической темы
        mapView.mapType = .hybrid
        
        // Устанавливаем английский язык для карты
        if #available(iOS 13.0, *) {
            mapView.preferredConfiguration = MKStandardMapConfiguration()
        }
        
        // Настраиваем Weather manager
        weatherManager.setMapView(mapView)
        
        // Добавляем Enhanced Weather overlay для лучшей видимости
        let enhancedOverlay = EnhancedWeatherOverlay(layerType: .precipitation)
        mapView.addOverlay(enhancedOverlay, level: .aboveLabels)
        
        // Добавляем gesture recognizer для тапов
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Обновляем аннотацию при изменении выбранной координаты
        if showAnnotation, let coordinate = selectedCoordinate {
            // Удаляем старые аннотации
            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
            
            // Добавляем новую аннотацию
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Selected Point"
            annotation.subtitle = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
            mapView.addAnnotation(annotation)
        } else {
            // Удаляем все аннотации кроме пользователя
            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        }
    }
    
    private func addNASAOverlay(to mapView: MKMapView) {
        // Используем WeatherOverlay для реальных погодных данных
        let overlay = WeatherOverlay(layerType: .precipitation)
        mapView.addOverlay(overlay, level: .aboveLabels)
        nasaOverlay = overlay
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onTap: onTap)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        let onTap: (CLLocationCoordinate2D) -> Void
        
        init(_ parent: MapViewRepresentable, onTap: @escaping (CLLocationCoordinate2D) -> Void) {
            self.parent = parent
            self.onTap = onTap
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // Обработка выбора аннотации
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Обработка изменения региона карты
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            onTap(coordinate)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let nasaOverlay = overlay as? NASAOverlay {
                return NASAOverlayRenderer(tileOverlay: nasaOverlay)
            } else if let simpleOverlay = overlay as? SimpleOverlay {
                return SimpleOverlayRenderer(tileOverlay: simpleOverlay)
            } else if let rainOverlay = overlay as? RainViewerOverlay {
                return RainViewerOverlayRenderer(tileOverlay: rainOverlay)
            } else if let weatherOverlay = overlay as? WeatherOverlay {
                return WeatherOverlayRenderer(tileOverlay: weatherOverlay)
            } else if let enhancedWeatherOverlay = overlay as? EnhancedWeatherOverlay {
                return EnhancedWeatherOverlayRenderer(tileOverlay: enhancedWeatherOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Tap Gesture Handler
extension MapViewRepresentable {
    func onTapGesture(perform action: @escaping (CLLocationCoordinate2D) -> Void) -> some View {
        self.overlay(
            TapGestureOverlay(onTap: action)
        )
    }
}

struct TapGestureOverlay: UIViewRepresentable {
    let onTap: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }
    
    class Coordinator: NSObject {
        let onTap: (CLLocationCoordinate2D) -> Void
        
        init(onTap: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onTap = onTap
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view?.superview as? MKMapView else { return }
            
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            onTap(coordinate)
        }
    }
}

