//
//  MainTabView.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some View {
        TabView {
            // Weather Map Tab
            WeatherMapView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "cloud.rain.fill")
                    Text("Weather")
                }
                .tag(0)
            
            // Forecast Tab
            ForecastView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Forecast")
                }
                .tag(1)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.cyan)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
