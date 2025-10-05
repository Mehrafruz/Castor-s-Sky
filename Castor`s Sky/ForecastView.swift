//
//  ForecastView.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI

struct ForecastView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ZStack {
            // Space-themed background
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.11, blue: 0.23), Color(red: 0.02, green: 0.05, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if viewModel.selectedCoordinate != nil {
                // Show NASA Precipitation Data
                PrecipitationForecastView(viewModel: viewModel)
            } else {
                // Show placeholder when no location is selected
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("NASA Hydrology Forecast")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Select a location on the map to view detailed hydrological data")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                    
                        // NASA Data Preview
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .font(.title)
                                    .foregroundColor(.cyan)
                                
                                VStack(alignment: .leading) {
                                    Text("NASA Hydrology Time Series")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("Real-time precipitation, soil moisture, temperature, and more")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "globe")
                                    .font(.title2)
                                    .foregroundColor(.cyan)
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
                            
                            // Data Types Preview
                            HStack(spacing: 20) {
                                VStack {
                                    Image(systemName: "cloud.rain.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text("Precipitation")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Image(systemName: "drop.fill")
                                        .font(.title2)
                                        .foregroundColor(.brown)
                                    Text("Soil Moisture")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Image(systemName: "thermometer")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                    Text("Temperature")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack {
                                    Image(systemName: "barometer")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                    Text("Pressure")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                    
                        // Instructions
                        VStack(spacing: 16) {
                            Text("How to use:")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("1.")
                                        .font(.headline)
                                        .foregroundColor(.cyan)
                                    Text("Go to the Weather tab")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                
                                HStack {
                                    Text("2.")
                                        .font(.headline)
                                        .foregroundColor(.cyan)
                                    Text("Tap anywhere on the map to select a location")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                
                                HStack {
                                    Text("3.")
                                        .font(.headline)
                                        .foregroundColor(.cyan)
                                    Text("Return to this tab to view NASA hydrological data")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

struct HourlyForecastCard: View {
    let hour: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(hour):00")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Image(systemName: "cloud.rain.fill")
                .font(.title2)
                .foregroundColor(.cyan)
            
            Text("\(Int.random(in: 15...25))°")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("\(Int.random(in: 20...80))%")
                .font(.caption)
                .foregroundColor(.cyan)
        }
        .frame(width: 60)
        .padding(.vertical, 12)
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

struct DailyForecastCard: View {
    let day: Int
    
    private var dayName: String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[day % 7]
    }
    
    var body: some View {
        HStack {
            Text(dayName)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 40, alignment: .leading)
            
            Image(systemName: "cloud.rain.fill")
                .font(.title3)
                .foregroundColor(.cyan)
                .frame(width: 30)
            
            Spacer()
            
            Text("\(Int.random(in: 20...80))%")
                .font(.subheadline)
                .foregroundColor(.cyan)
                .frame(width: 40, alignment: .trailing)
            
            Text("\(Int.random(in: 15...25))°")
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
    ForecastView(viewModel: AppViewModel())
}
