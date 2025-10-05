//
//  WeatherDataManager.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import Foundation
import CoreLocation
import Combine

// MARK: - Weather Data Models
struct WeatherMain: Codable {
    let temp: Double
    let humidity: Int
    let pressure: Double
}

struct WeatherWind: Codable {
    let speed: Double
}

struct WeatherRain: Codable {
    let oneHour: Double?
    
    enum CodingKeys: String, CodingKey {
        case oneHour = "1h"
    }
}

struct WeatherInfo: Codable {
    let main: String
    let description: String
}

struct WeatherResponse: Codable {
    let main: WeatherMain
    let wind: WeatherWind
    let rain: WeatherRain?
    let weather: [WeatherInfo]
}

// MARK: - Weather Data Manager
class WeatherDataManager: ObservableObject {
    @Published var weatherResponse: WeatherResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hourlyPrecipitation: [HourlyPrecip] = [] // next 24h
    
    private let apiKey = "5bec64a73f11f243090191161ccf6544"
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let openMeteoBase = "https://api.open-meteo.com/v1/forecast"
    
    func fetchCurrentWeather(for coordinate: CLLocationCoordinate2D) {
        isLoading = true
        errorMessage = nil
        
        let urlString = "\(baseURL)/weather?lat=\(coordinate.latitude)&lon=\(coordinate.longitude)&appid=\(apiKey)&units=metric"
        
        print("🌤️ Fetching weather for: \(coordinate.latitude), \(coordinate.longitude)")
        print("🌤️ URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("CastorSky/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                // Debug: Print raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🌤️ Raw API response: \(responseString.prefix(500))")
                }
                
                do {
                    let weatherResponse = try JSONDecoder().decode(WeatherResponse.self, from: data)
                    self?.weatherResponse = weatherResponse
                    print("🌤️ Weather data loaded successfully: \(weatherResponse.main.temp)°C")
                } catch {
                    self?.errorMessage = "Failed to parse weather data: \(error.localizedDescription)"
                    print("❌ Weather parsing error: \(error)")
                    print("❌ Raw data: \(String(data: data, encoding: .utf8)?.prefix(200) ?? "nil")")
                }
            }
        }.resume()
    }

    // MARK: - Hourly precipitation (next 24h) via Open‑Meteo (no API key)
    struct OMForecastResponse: Codable {
        let hourly: OMHourly?
    }
    struct OMHourly: Codable {
        let time: [String]
        let precipitation: [Double]?
    }
    struct HourlyPrecip: Identifiable {
        let id = UUID()
        let date: Date
        let valueMm: Double
        var hourLabel: String {
            let f = DateFormatter()
            f.dateFormat = "H"
            return f.string(from: date)
        }
    }
    
    func fetchHourlyPrecipitation(for coordinate: CLLocationCoordinate2D) {
        let now = Date()
        let end = Calendar.current.date(byAdding: .hour, value: 24, to: now) ?? now
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .current
        let startStr = df.string(from: now)
        let endStr = df.string(from: end)
        var comps = URLComponents(string: openMeteoBase)!
        comps.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "hourly", value: "precipitation"),
            URLQueryItem(name: "start_date", value: startStr),
            URLQueryItem(name: "end_date", value: endStr),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = comps.url else { return }
        var request = URLRequest(url: url)
        request.setValue("CastorSky/1.0", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard error == nil, let data = data else { return }
                do {
                    let decoded = try JSONDecoder().decode(OMForecastResponse.self, from: data)
                    guard let hourly = decoded.hourly else { return }
                    let tf = DateFormatter()
                    tf.dateFormat = "yyyy-MM-dd'T'HH:mm"
                    tf.timeZone = .current
                    var items: [HourlyPrecip] = []
                    let values = hourly.precipitation ?? Array(repeating: 0, count: hourly.time.count)
                    for (i, tstr) in hourly.time.enumerated() {
                        guard let d = tf.date(from: tstr) else { continue }
                        if d >= now && d < end {
                            let v = max(0, values[i])
                            items.append(HourlyPrecip(date: d, valueMm: v))
                        }
                    }
                    // Ensure at most 24 items
                    self?.hourlyPrecipitation = Array(items.prefix(24))
                } catch {
                    // ignore for now
                }
            }
        }.resume()
    }
    
    // Computed properties for easy access
    var temperatureString: String {
        guard let weather = weatherResponse else { return "N/A" }
        return "\(Int(weather.main.temp))°C"
    }
    
    var humidityString: String {
        guard let weather = weatherResponse else { return "N/A" }
        return "\(weather.main.humidity)%"
    }
    
    var pressureString: String {
        guard let weather = weatherResponse else { return "N/A" }
        return "\(Int(weather.main.pressure)) hPa"
    }
    
    var windSpeedString: String {
        guard let weather = weatherResponse else { return "N/A" }
        return "\(Int(weather.wind.speed * 3.6)) km/h" // Convert m/s to km/h
    }
    
    var precipitationString: String {
        guard let weather = weatherResponse else { return "N/A" }
        if let rain = weather.rain?.oneHour {
            return "\(Int(rain)) mm/h"
        } else {
            return "0 mm/h"
        }
    }
}
