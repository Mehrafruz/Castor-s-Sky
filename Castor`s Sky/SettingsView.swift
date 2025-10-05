//
//  SettingsView.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var temperatureUnit = "Celsius"
    @State private var windSpeedUnit = "km/h"
    @State private var selectedTheme = "Space"
    
    var body: some View {
        ZStack {
            // Space-themed background
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.11, blue: 0.23), Color(red: 0.02, green: 0.05, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Customize your weather experience")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 20)
                    
                    // App Info
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.title2)
                                .foregroundColor(.cyan)
                            
                            VStack(alignment: .leading) {
                                Text("Castor's Sky")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Version 1.0.0")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Notification Settings
                    SettingsSection(title: "Notifications") {
                        SettingsToggle(
                            icon: "bell.fill",
                            title: "Weather Alerts",
                            subtitle: "Get notified about severe weather",
                            isOn: $notificationsEnabled
                        )
                    }
                    
                    // Units Settings
                    SettingsSection(title: "Units") {
                        SettingsPicker(
                            icon: "thermometer",
                            title: "Temperature",
                            subtitle: "Choose temperature unit",
                            selection: $temperatureUnit,
                            options: ["Celsius", "Fahrenheit"]
                        )
                        
                        SettingsPicker(
                            icon: "wind",
                            title: "Wind Speed",
                            subtitle: "Choose wind speed unit",
                            selection: $windSpeedUnit,
                            options: ["km/h", "mph", "m/s"]
                        )
                    }
                    
                    // Theme Settings
                    SettingsSection(title: "Appearance") {
                        SettingsPicker(
                            icon: "paintbrush.fill",
                            title: "Theme",
                            subtitle: "Choose app theme",
                            selection: $selectedTheme,
                            options: ["Space", "Dark", "Light"]
                        )
                    }
                    
                    // Data Source
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "cloud.fill")
                                .font(.title2)
                                .foregroundColor(.cyan)
                            
                            VStack(alignment: .leading) {
                                Text("Data Source")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("OpenWeatherMap API")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                content
            }
        }
    }
}

struct SettingsToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cyan)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.cyan.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct SettingsPicker: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.cyan)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(.cyan)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.cyan.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SettingsView()
}


