//
//  EnglishMapView.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct EnglishMapView: UIViewRepresentable {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var showAnnotation: Bool
    @ObservedObject var rainViewerManager: RainViewerLayerManager
    @ObservedObject var weatherManager: WeatherLayerManager
    @ObservedObject var enhancedWeatherManager: EnhancedWeatherLayerManager
    let onTap: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        context.coordinator.mapView = mapView
        context.coordinator.requestLocationAuthorization()
        // Try to zoom immediately if already authorized and location available
        context.coordinator.attemptInitialZoom()
        
        // Настройка для английского языка
        setupEnglishLanguage(for: mapView)
        
        // Настройка начального региона (мир)
        let worldRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 120.0, longitudeDelta: 120.0)
        )
        mapView.setRegion(worldRegion, animated: false)
        
        // Настройка стиля карты
        mapView.mapType = .hybrid
        
        // Настраиваем Weather manager
        weatherManager.setMapView(mapView)
        
        // Настраиваем Enhanced Weather manager
        enhancedWeatherManager.setMapView(mapView)
        
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onTap: onTap)
    }
    
    private func setupEnglishLanguage(for mapView: MKMapView) {
        // Принудительно устанавливаем английский язык для карты
        if #available(iOS 13.0, *) {
            // Используем кастомную конфигурацию с английским языком
            let configuration = EnglishMapConfiguration()
            mapView.preferredConfiguration = configuration
        }
        
        // Дополнительные настройки для английского языка
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = false
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
        
        // Принудительно устанавливаем английский язык через UserDefaults
        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        UserDefaults.standard.set("en", forKey: "AppleLocale")
        UserDefaults.standard.synchronize()
        
        // Устанавливаем регион с английскими названиями
        let englishRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 54.0, longitude: 10.0), // Центр Европы
            span: MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 30.0)
        )
        mapView.setRegion(englishRegion, animated: false)
        
        // Дополнительная настройка для принудительного английского языка
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Повторно устанавливаем английский язык после загрузки карты
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: EnglishMapView
        let onTap: (CLLocationCoordinate2D) -> Void
        let locationManager = CLLocationManager()
        weak var mapView: MKMapView?
        private var hasZoomedToUser = false
        
        init(_ parent: EnglishMapView, onTap: @escaping (CLLocationCoordinate2D) -> Void) {
            self.parent = parent
            self.onTap = onTap
            super.init()
            locationManager.delegate = self
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

// MARK: - CLLocationManagerDelegate
extension EnglishMapView.Coordinator: CLLocationManagerDelegate {
    func attemptInitialZoom() {
        let status = CLLocationManager.authorizationStatus()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else { return }
        if let coordinate = locationManager.location?.coordinate, let mapView = mapView {
            hasZoomedToUser = true
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12))
            mapView.setRegion(region, animated: true)
            mapView.userTrackingMode = .follow
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    func requestLocationAuthorization() {
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            mapView?.userTrackingMode = .follow
            if let coordinate = locationManager.location?.coordinate, let mapView = mapView {
                hasZoomedToUser = true
                let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12))
                mapView.setRegion(region, animated: true)
            } else {
                locationManager.startUpdatingLocation()
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            mapView?.userTrackingMode = .follow
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate, let mapView = mapView else { return }
        if !hasZoomedToUser {
            hasZoomedToUser = true
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12))
            mapView.setRegion(region, animated: true)
        }
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // No-op
    }
}

