//
//  Castor_s_SkyApp.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI

@main
struct Castor_s_SkyApp: App {
    init() {
        // Принудительно устанавливаем английский язык для карт
        setupEnglishLanguage()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
    
    private func setupEnglishLanguage() {
        // Принудительно устанавливаем английский язык для всего приложения
        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        UserDefaults.standard.set("en", forKey: "AppleLocale")
        UserDefaults.standard.synchronize()
        
        // Устанавливаем английский язык для MapKit
        if #available(iOS 13.0, *) {
            // Дополнительные настройки для английского языка карт
        }
    }
}
