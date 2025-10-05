//
//  WeatherCardView.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI
import MapKit

struct WeatherCardView: View {
    let coordinate: CLLocationCoordinate2D
    let cityName: String?
    @ObservedObject var weatherManager: WeatherLayerManager
    @Binding var isPresented: Bool
    
    @StateObject private var weatherDataManager = WeatherDataManager()
    @State private var dragOffset: CGFloat = 0
    @State private var isExpanded = false
    @State private var resolvedPlaceName: String?
    
    private var locationDescription: String {
        if let name = cityName ?? resolvedPlaceName {
            return name
        } else {
            return String(format: "%.4f°N, %.4f°E", coordinate.latitude, coordinate.longitude)
        }
    }
    
    init(coordinate: CLLocationCoordinate2D, cityName: String? = nil, weatherManager: WeatherLayerManager, isPresented: Binding<Bool>) {
        self.coordinate = coordinate
        self.cityName = cityName
        self.weatherManager = weatherManager
        self._isPresented = isPresented
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(.white.opacity(0.6))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Weather Forecast")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(locationDescription)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Weather Info
                VStack(spacing: 16) {
                    if weatherDataManager.isLoading {
                        // Loading indicator
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                            Text("Loading weather data...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let errorMessage = weatherDataManager.errorMessage {
                        // Error state
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.title2)
                                .foregroundColor(.orange)
                            Text("Failed to load weather data")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Current conditions
                        HStack(spacing: 12) {
                            WeatherInfoCard(
                                icon: "cloud.rain.fill",
                                title: "Precipitation",
                                value: weatherDataManager.precipitationString,
                                color: .cyan
                            )
                            
                            WeatherInfoCard(
                                icon: "thermometer",
                                title: "Temperature",
                                value: weatherDataManager.temperatureString,
                                color: .orange
                            )
                            
                            WeatherInfoCard(
                                icon: "wind",
                                title: "Wind",
                                value: weatherDataManager.windSpeedString,
                                color: .blue
                            )
                        }
                    }
                    
                    // 24h Forecast Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("24h Precipitation Forecast")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        // Real hourly precipitation bars (next 24h)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(weatherDataManager.hourlyPrecipitation) { hour in
                                    VStack(spacing: 4) {
                                        Rectangle()
                                            .fill(.cyan.opacity(min(0.9, max(0.2, hour.valueMm / 5.0))))
                                            .frame(width: 12, height: max(6, CGFloat(min(60, hour.valueMm * 6))))
                                            .cornerRadius(2)
                                        Text(hour.hourLabel)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.cyan.opacity(0.2), lineWidth: 1)
                )
        )
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = max(0, value.translation.height)
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            weatherDataManager.fetchCurrentWeather(for: coordinate)
            weatherDataManager.fetchHourlyPrecipitation(for: coordinate)
            // Reverse geocode if no explicit city name provided
            if cityName == nil {
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                    if let placemark = placemarks?.first {
                        // Prefer locality, then administrativeArea, then name
                        let components = [placemark.locality, placemark.subLocality, placemark.administrativeArea, placemark.country].compactMap { $0 }
                        if let best = components.first {
                            resolvedPlaceName = best
                        } else if let name = placemark.name {
                            resolvedPlaceName = name
                        }
                    }
                }
            }
        }
    }
}

struct WeatherInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    WeatherCardView(
        coordinate: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176),
        cityName: "Moscow",
        weatherManager: WeatherLayerManager(),
        isPresented: .constant(true)
    )
    .background(Color.black)
}

