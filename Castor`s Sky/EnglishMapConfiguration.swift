//
//  EnglishMapConfiguration.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import MapKit
import UIKit

@available(iOS 13.0, *)
class EnglishMapConfiguration: MKStandardMapConfiguration {
    
    override init() {
        super.init()
        setupEnglishLanguage()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupEnglishLanguage() {
        // Принудительно устанавливаем английский язык
        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        UserDefaults.standard.set("en", forKey: "AppleLocale")
        UserDefaults.standard.synchronize()
        
        // Настройки для английского языка
        self.pointOfInterestFilter = .includingAll
        self.showsTraffic = false
    }
}

// MARK: - English Map View Controller
class EnglishMapViewController: UIViewController {
    private var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEnglishMap()
    }
    
    private func setupEnglishMap() {
        mapView = MKMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        
        // Принудительно устанавливаем английский язык
        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        UserDefaults.standard.set("en", forKey: "AppleLocale")
        UserDefaults.standard.synchronize()
        
        // Настройка карты для английского языка
        if #available(iOS 13.0, *) {
            let configuration = EnglishMapConfiguration()
            mapView.preferredConfiguration = configuration
        }
        
        // Устанавливаем регион с английскими названиями
        let englishRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 54.0, longitude: 10.0),
            span: MKCoordinateSpan(latitudeDelta: 20.0, longitudeDelta: 30.0)
        )
        mapView.setRegion(englishRegion, animated: false)
        
        // Дополнительные настройки
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = false
        mapView.showsBuildings = true
        mapView.showsPointsOfInterest = true
    }
}


