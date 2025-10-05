//
//  NASAHydrologyData.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import Foundation
import SwiftUI
import Combine
import MapKit

// MARK: - NASA Hydrology Data Models
struct NASAHydrologyData: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let precipitation: Double? // mm/hour
    let soilMoisture: Double? // m³/m³
    let temperature: Double? // °C
    let humidity: Double? // %
    let pressure: Double? // hPa
    
    enum CodingKeys: String, CodingKey {
        case timestamp = "time"
        case latitude = "lat"
        case longitude = "lon"
        case precipitation = "precip"
        case soilMoisture = "soil_moisture"
        case temperature = "temp"
        case humidity = "humidity"
        case pressure = "pressure"
    }
}

// MARK: - Precipitation Data Models (для экрана осадков)
struct PrecipitationDataPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let precipitation: Double // mm
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case date, precipitation, latitude, longitude
    }
}

struct RainyDay: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let precipitation: Double // mm
    let isRainy: Bool
    let intensity: RainIntensity
    
    enum RainIntensity: String, CaseIterable, Codable {
        case none = "No Rain"
        case light = "Light Rain"
        case moderate = "Moderate Rain"
        case heavy = "Heavy Rain"
        case extreme = "Extreme Rain"
        
        var color: String {
            switch self {
            case .none: return "gray"
            case .light: return "blue"
            case .moderate: return "cyan"
            case .heavy: return "orange"
            case .extreme: return "red"
            }
        }
        
        var threshold: Double {
            switch self {
            case .none: return 0
            case .light: return 0.1
            case .moderate: return 2.5
            case .heavy: return 10.0
            case .extreme: return 25.0
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case date, precipitation, isRainy, intensity
    }
}

// MARK: - NASA Hydrology API Manager
class NASAHydrologyManager: ObservableObject {
    @Published var hydrologyData: [NASAHydrologyData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var precipitationData: [PrecipitationDataPoint] = []
    @Published var rainyDays: [RainyDay] = []
    
    // Базовые кандидаты путей TSS (перебираем до успеха)
    private let tssBaseCandidates: [String] = [
        "https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/timeseries.cgi",
        "https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/timeseries",
        "https://hydro1.gesdisc.eosdis.nasa.gov/daac-bin/access/timeseries.cgi",
        "https://disc.gsfc.nasa.gov/daac-bin/timeseries.cgi",
        "https://disc.gsfc.nasa.gov/daac-bin/timeseries",
        "https://disc.gsfc.nasa.gov/daac-bin/access/timeseries.cgi"
    ]
    
    // Earthdata Login Bearer Token (опционально)
    private var edlBearerToken: String?
    
    // Debug logging
    private let debugLogging = true
    
    // URLSession
    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 30
        cfg.timeoutIntervalForResource = 60
        cfg.allowsExpensiveNetworkAccess = true
        cfg.allowsConstrainedNetworkAccess = true
        return URLSession(configuration: cfg)
    }()
    
    // MARK: - Устойчивость: кэш/схемы отказов/ретраи
    
    // Памятный кэш (TTL)
    private struct CacheEntry<T> {
        let timestamp: Date
        let value: T
    }
    private var hydroCache: [String: CacheEntry<[NASAHydrologyData]>] = [:]
    private var precipCache: [String: CacheEntry<[PrecipitationDataPoint]>] = [:]
    private let cacheTTL: TimeInterval = 15 * 60 // 15 минут
    
    // Circuit breaker для TSS
    private var tssCircuitOpenUntil: Date?
    private let tssOpenDuration: TimeInterval = 10 * 60 // 10 минут
    private var consecutiveTSSFailures = 0
    private let tssFailureThreshold = 3
    
    // Отмена параллельных задач
    private var currentHydroTask: Task<Void, Never>?
    private var currentPrecipTask: Task<Void, Never>?
    
    // MARK: - Public API
    func setEDLBearerToken(_ token: String?) {
        edlBearerToken = token
        if debugLogging {
            print("EDL token set: \(token != nil ? "YES" : "NO")")
        }
    }
    
    func fetchHydrologyData(for coordinate: CLLocationCoordinate2D, days: Int = 7) {
        // Отмена предыдущей задачи
        currentHydroTask?.cancel()
        currentHydroTask = Task { [weak self] in
            guard let self else { return }
            if debugLogging {
                print("fetchHydrologyData called for lat=\(coordinate.latitude), lon=\(coordinate.longitude), days=\(days)")
            }
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            let endDate = clampToPreviousHour(Date())
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
            
            // Кэш
            let key = self.cacheKey(lat: coordinate.latitude, lon: coordinate.longitude, days: days, kind: "hydro")
            if let cached = self.hydroCache[key], Date().timeIntervalSince(cached.timestamp) < self.cacheTTL {
                if self.debugLogging { print("Hydro cache hit for key \(key)") }
                await MainActor.run {
                    self.hydrologyData = cached.value.sorted { $0.timestamp > $1.timestamp }
                    self.isLoading = false
                }
                return
            }
            
            // Попытка TSS (если circuit закрыт)
            let shouldTryTSS = !(self.tssCircuitOpenUntil.map { Date() < $0 } ?? false)
            do {
                let data: [NASAHydrologyData]
                if shouldTryTSS {
                    data = try await self.fetchHydrologyViaTSS(coordinate: coordinate, startDate: startDate, endDate: endDate)
                    // Сброс счётчика ошибок TSS
                    self.consecutiveTSSFailures = 0
                } else {
                    if self.debugLogging { print("TSS circuit open until \(self.tssCircuitOpenUntil!) — skip TSS, use POWER") }
                    data = try await self.fetchFromNASAPOWER(for: coordinate, days: days)
                    await MainActor.run {
                        self.errorMessage = "Using NASA POWER open API (TSS temporarily unavailable). Soil moisture not available."
                    }
                }
                
                // Кэшируем и обновляем UI
                self.hydroCache[key] = CacheEntry(timestamp: Date(), value: data)
                await MainActor.run {
                    self.hydrologyData = data.sorted { $0.timestamp > $1.timestamp }
                    self.isLoading = false
                    if self.debugLogging {
                        print("Hydrology loaded from \(shouldTryTSS ? "TSS" : "POWER"): \(data.count) points")
                    }
                }
            } catch {
                // TSS мог упасть — открываем circuit и уходим на POWER/Open‑Meteo с ретраями
                self.registerTSSFailure()
                if self.debugLogging {
                    print("Hydrology TSS failed (\(error)). Falling back to POWER with retries, then Open‑Meteo.")
                }
                do {
                    let data = try await self.withRetries(maxAttempts: 3, baseDelay: 1.0) {
                        try await self.fetchFromNASAPOWER(for: coordinate, days: days)
                    }
                    self.hydroCache[key] = CacheEntry(timestamp: Date(), value: data)
                    await MainActor.run {
                        self.hydrologyData = data.sorted { $0.timestamp > $1.timestamp }
                        self.isLoading = false
                        self.errorMessage = "Using NASA POWER (TSS unavailable). Soil moisture not available."
                    }
                } catch {
                    // Try Open‑Meteo as last resort
                    if self.debugLogging { print("POWER failed (\(error)). Falling back to Open‑Meteo ERA5.") }
                    do {
                        let data = try await self.withRetries(maxAttempts: 2, baseDelay: 1.0) {
                            try await self.fetchFromOpenMeteo(for: coordinate, days: days)
                        }
                        self.hydroCache[key] = CacheEntry(timestamp: Date(), value: data)
                        await MainActor.run {
                            self.hydrologyData = data.sorted { $0.timestamp > $1.timestamp }
                            self.isLoading = false
                            self.errorMessage = "Using Open‑Meteo ERA5 (NASA endpoints unavailable)."
                        }
                    } catch {
                        await MainActor.run {
                            self.isLoading = false
                            self.errorMessage = "Failed to load from NASA TSS/POWER and Open‑Meteo: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
    
    func fetchRealPrecipitationData(for coordinate: CLLocationCoordinate2D, days: Int = 30) {
        currentPrecipTask?.cancel()
        currentPrecipTask = Task { [weak self] in
            guard let self else { return }
            if debugLogging {
                print("fetchRealPrecipitationData called for lat=\(coordinate.latitude), lon=\(coordinate.longitude), days=\(days)")
            }
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            let endDate = clampToPreviousHour(Date())
            let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
            
            let key = self.cacheKey(lat: coordinate.latitude, lon: coordinate.longitude, days: days, kind: "precip")
            if let cached = self.precipCache[key], Date().timeIntervalSince(cached.timestamp) < self.cacheTTL {
                if self.debugLogging { print("Precip cache hit for key \(key)") }
                await MainActor.run {
                    self.precipitationData = cached.value.sorted { $0.date > $1.date }
                    self.rainyDays = self.makeRainyDays(from: self.precipitationData)
                    self.isLoading = false
                }
                return
            }
            
            // Попытка TSS
            let shouldTryTSS = !(self.tssCircuitOpenUntil.map { Date() < $0 } ?? false)
            do {
                if shouldTryTSS {
                    let nldasURLs = try self.buildTSSCandidateURLs(
                        dataset: "NLDAS_FORA0125_H.002",
                        variables: ["apcpsfc"],
                        coordinate: coordinate,
                        startDate: startDate,
                        endDate: endDate
                    )
                    let data = try await self.withRetries(maxAttempts: 2, baseDelay: 0.8) {
                        try await self.fetchFirstSuccess(urls: nldasURLs)
                    }
                    let parsed = try self.parseTSSResponse(data)
                    let daily = self.aggregatePrecipitationDaily(parsed, coordinate: coordinate)
                    // Merge recent 3 days with fallback if NASA daily data missing/invalid
                    let patched = try await self.fillRecentDaysIfMissing(baseDaily: daily, coordinate: coordinate, recentDays: 3)
                    self.precipCache[key] = CacheEntry(timestamp: Date(), value: patched)
                    self.consecutiveTSSFailures = 0
                    await MainActor.run {
                        self.precipitationData = patched.sorted { $0.date > $1.date }
                        self.rainyDays = self.makeRainyDays(from: self.precipitationData)
                        self.isLoading = false
                    }
                } else {
                    if self.debugLogging { print("TSS circuit open — skip TSS, use POWER for precip") }
                    let powerSeries = try await self.fetchFromNASAPOWER(for: coordinate, days: days)
                    let daily = self.aggregatePrecipitationDailyFromPower(powerSeries, coordinate: coordinate)
                    let patched = try await self.fillRecentDaysIfMissing(baseDaily: daily, coordinate: coordinate, recentDays: 3)
                    self.precipCache[key] = CacheEntry(timestamp: Date(), value: patched)
                    await MainActor.run {
                        self.precipitationData = patched.sorted { $0.date > $1.date }
                        self.rainyDays = self.makeRainyDays(from: self.precipitationData)
                        self.isLoading = false
                        self.errorMessage = "Using NASA POWER open API (TSS unavailable)."
                    }
                }
            } catch {
                self.registerTSSFailure()
                if self.debugLogging {
                    print("TSS precipitation failed (\(error)). Falling back to POWER with retries, then Open‑Meteo.")
                }
                do {
                    let powerSeries = try await self.withRetries(maxAttempts: 3, baseDelay: 1.0) {
                        try await self.fetchFromNASAPOWER(for: coordinate, days: days)
                    }
                    let daily = self.aggregatePrecipitationDailyFromPower(powerSeries, coordinate: coordinate)
                    let patched = try await self.fillRecentDaysIfMissing(baseDaily: daily, coordinate: coordinate, recentDays: 3)
                    self.precipCache[key] = CacheEntry(timestamp: Date(), value: patched)
                    await MainActor.run {
                        self.precipitationData = patched.sorted { $0.date > $1.date }
                        self.rainyDays = self.makeRainyDays(from: self.precipitationData)
                        self.isLoading = false
                        self.errorMessage = "Using NASA POWER open API (TSS unavailable)."
                    }
                } catch {
                    // Open‑Meteo final fallback
                    do {
                        let omSeries = try await self.withRetries(maxAttempts: 2, baseDelay: 1.0) {
                            try await self.fetchFromOpenMeteo(for: coordinate, days: days)
                        }
                        let daily = self.aggregatePrecipitationDailyFromOpenMeteo(omSeries, coordinate: coordinate)
                        self.precipCache[key] = CacheEntry(timestamp: Date(), value: daily)
                        await MainActor.run {
                            self.precipitationData = daily.sorted { $0.date > $1.date }
                            self.rainyDays = self.makeRainyDays(from: self.precipitationData)
                            self.isLoading = false
                            self.errorMessage = "Using Open‑Meteo ERA5 (NASA endpoints unavailable)."
                        }
                    } catch {
                        await MainActor.run {
                            self.isLoading = false
                            self.errorMessage = "Failed to load precipitation from NASA TSS/POWER and Open‑Meteo: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Ретраи/схемы отказов
    
    private func withRetries<T>(
        maxAttempts: Int,
        baseDelay: Double,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var attempt = 0
        var lastError: Error?
        while attempt < maxAttempts {
            if Task.isCancelled { throw CancellationError() }
            do {
                return try await operation()
            } catch {
                lastError = error
                attempt += 1
                if attempt >= maxAttempts { break }
                // экспоненциальная задержка + джиттер
                let jitter = Double.random(in: 0...0.3)
                let delay = pow(2.0, Double(attempt - 1)) * baseDelay + jitter
                if debugLogging {
                    print("Retry \(attempt)/\(maxAttempts) in \(String(format: "%.2f", delay))s due to: \(error)")
                }
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        throw lastError ?? URLError(.cannotLoadFromNetwork)
    }
    
    private func registerTSSFailure() {
        consecutiveTSSFailures += 1
        if consecutiveTSSFailures >= tssFailureThreshold {
            tssCircuitOpenUntil = Date().addingTimeInterval(tssOpenDuration)
            if debugLogging {
                print("TSS circuit opened until \(tssCircuitOpenUntil!) after \(consecutiveTSSFailures) failures")
            }
            consecutiveTSSFailures = 0
        }
    }
    
    // MARK: - Вспомогательные ключи/даты
    
    private func cacheKey(lat: Double, lon: Double, days: Int, kind: String) -> String {
        let latR = (lat * 100).rounded() / 100 // округлим до 0.01°
        let lonR = (lon * 100).rounded() / 100
        return "\(kind)-\(latR)-\(lonR)-\(days)"
    }
    
    private func clampToPreviousHour(_ date: Date) -> Date {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: date)
        return cal.date(from: comps) ?? date
    }
    
    // MARK: - TSS Networking
    
    private enum TSSAPIError: Error {
        case urlBuildFailed
        case unauthorized
        case invalidResponse(message: String, sample: String?)
        case decodingFailed
        case network(Error)
        case allCandidatesFailed
    }
    
    private func buildTSSCandidateURLs(
        dataset: String,
        variables: [String],
        coordinate: CLLocationCoordinate2D,
        startDate: Date,
        endDate: Date
    ) throws -> [URL] {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime, .withDashSeparatorInDate]
        let start = iso.string(from: startDate)
        let end = iso.string(from: endDate)
        
        var urls: [URL] = []
        for base in tssBaseCandidates {
            for formatKey in ["type", "format"] {
                var comps = URLComponents(string: base)
                comps?.queryItems = [
                    URLQueryItem(name: "dataset", value: dataset),
                    URLQueryItem(name: "variable", value: variables.joined(separator: ",")),
                    URLQueryItem(name: "location", value: "GEOM:POINT(\(coordinate.longitude) \(coordinate.latitude))"),
                    URLQueryItem(name: "startDate", value: start),
                    URLQueryItem(name: "endDate", value: end),
                    URLQueryItem(name: formatKey, value: "json")
                ]
                if let url = comps?.url {
                    urls.append(url)
                }
            }
        }
        if urls.isEmpty { throw TSSAPIError.urlBuildFailed }
        if debugLogging {
            print("Built \(urls.count) candidate URLs. First: \(urls.first!.absoluteString)")
        }
        return urls
    }
    
    private func fetchFirstSuccess(urls: [URL]) async throws -> Data {
        var lastError: Error?
        for url in urls {
            do {
                let data = try await fetchTSSJSON(url: url)
                return data
            } catch {
                lastError = error
                if debugLogging {
                    print("Candidate failed: \(url.absoluteString). Error: \(error)")
                }
                continue
            }
        }
        throw lastError ?? TSSAPIError.allCandidatesFailed
    }
    
    private func fetchTSSJSON(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("CastorSky/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json,*/*;q=0.8", forHTTPHeaderField: "Accept")
        if let token = edlBearerToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if debugLogging {
            print("Requesting: \(url.absoluteString)")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse {
                if debugLogging {
                    print("Response status: \(http.statusCode) for \(url.host ?? "")")
                }
                if http.statusCode == 401 || http.statusCode == 403 {
                    throw TSSAPIError.unauthorized
                }
                if http.statusCode < 200 || http.statusCode >= 300 {
                    throw TSSAPIError.invalidResponse(message: "HTTP \(http.statusCode)", sample: previewSample(from: data))
                }
            }
            if let s = String(data: data, encoding: .utf8), s.lowercased().contains("<html") {
                if debugLogging {
                    print("HTML received instead of JSON (likely login/404 page).")
                }
                throw TSSAPIError.invalidResponse(message: "HTML page returned.", sample: String(s.prefix(300)))
            }
            if debugLogging {
                print("Received \(data.count) bytes.")
            }
            return data
        } catch let err as TSSAPIError {
            throw err
        } catch {
            if debugLogging {
                print("Network error: \(error.localizedDescription)")
            }
            throw TSSAPIError.network(error)
        }
    }
    
    private func previewSample(from data: Data) -> String? {
        guard let s = String(data: data, encoding: .utf8) else { return nil }
        return String(s.prefix(300))
    }
    
    // MARK: - TSS Parsing
    
    private struct TSSResponse: Decodable {
        let data: [TSSDatum]
    }
    
    private struct TSSDatum: Decodable {
        let time: String
        let lat: Double?
        let lon: Double?
        // NLDAS
        let apcpsfc: Double?
        let tmp2m: Double?
        let pressfc: Double?
        let spfh2m: Double?
        // GLDAS
        let SoilMoi0_10cm_inst: Double?
    }
    
    private func parseTSSResponse(_ data: Data) throws -> [TSSDatum] {
        do {
            let decoder = JSONDecoder()
            let resp = try decoder.decode(TSSResponse.self, from: data)
            if debugLogging {
                print("Parsed TSS items: \(resp.data.count)")
            }
            return resp.data
        } catch {
            if debugLogging, let s = String(data: data, encoding: .utf8) {
                print("Decoding failed. Sample: \(String(s.prefix(300)))")
            }
            throw TSSAPIError.decodingFailed
        }
    }
    
    // MARK: - Merge and conversions
    
    private func fetchHydrologyViaTSS(coordinate: CLLocationCoordinate2D, startDate: Date, endDate: Date) async throws -> [NASAHydrologyData] {
        // 1) NLDAS
        let nldasVars = ["apcpsfc", "tmp2m", "pressfc", "spfh2m"]
        let nldasURLs = try buildTSSCandidateURLs(
            dataset: "NLDAS_FORA0125_H.002",
            variables: nldasVars,
            coordinate: coordinate,
            startDate: startDate,
            endDate: endDate
        )
        // 2) GLDAS
        let gldasVars = ["SoilMoi0_10cm_inst"]
        let gldasURLs = try buildTSSCandidateURLs(
            dataset: "GLDAS_NOAH025_3H_2.0",
            variables: gldasVars,
            coordinate: coordinate,
            startDate: startDate,
            endDate: endDate
        )
        
        async let nldasDataTask: Data = withRetries(maxAttempts: 2, baseDelay: 0.8) {
            try await self.fetchFirstSuccess(urls: nldasURLs)
        }
        async let gldasDataTask: Data = withRetries(maxAttempts: 2, baseDelay: 0.8) {
            try await self.fetchFirstSuccess(urls: gldasURLs)
        }
        
        let nldasData = try await nldasDataTask
        let gldasData = try await gldasDataTask
        
        let nldasParsed = try parseTSSResponse(nldasData)
        let gldasParsed = try parseTSSResponse(gldasData)
        
        let merged = try mergeTSSData(
            nldas: nldasParsed,
            gldas: gldasParsed,
            fallbackLat: coordinate.latitude,
            fallbackLon: coordinate.longitude
        )
        return merged.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func mergeTSSData(
        nldas: [TSSDatum],
        gldas: [TSSDatum],
        fallbackLat: Double,
        fallbackLon: Double
    ) throws -> [NASAHydrologyData] {
        var map: [Date: Partial] = [:]
        
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime]
        
        func parseDate(_ s: String) -> Date? {
            if let d = iso.date(from: s) { return d }
            let f1 = DateFormatter()
            f1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            f1.timeZone = .utc
            if let d = f1.date(from: s) { return d }
            let f2 = DateFormatter()
            f2.dateFormat = "yyyy-MM-dd"
            f2.timeZone = .utc
            return f2.date(from: s)
        }
        
        // NLDAS (почасовые)
        for item in nldas {
            guard let date = parseDate(item.time) else { continue }
            var p = map[date] ?? Partial(lat: item.lat ?? fallbackLat, lon: item.lon ?? fallbackLon)
            if let v = item.apcpsfc { p.precip = v }           // mm/h
            if let v = item.tmp2m { p.tempC = v - 273.15 }     // K -> °C
            if let v = item.pressfc { p.pressHpa = v / 100.0 } // Pa -> hPa
            if let v = item.spfh2m { p.specHumidity = v }      // kg/kg
            map[date] = p
        }
        
        // GLDAS (3-часовые)
        for item in gldas {
            guard let date = parseDate(item.time) else { continue }
            var p = map[date] ?? Partial(lat: item.lat ?? fallbackLat, lon: item.lon ?? fallbackLon)
            if let v = item.SoilMoi0_10cm_inst { p.soil = v }  // m³/m³
            map[date] = p
        }
        
        // Собираем итог
        var result: [NASAHydrologyData] = []
        for (date, p) in map {
            let rh = computeRelativeHumidityPercent(tempC: p.tempC, pressureHpa: p.pressHpa, specificHumidity: p.specHumidity)
            result.append(
                NASAHydrologyData(
                    timestamp: date,
                    latitude: p.lat,
                    longitude: p.lon,
                    precipitation: p.precip,
                    soilMoisture: p.soil,
                    temperature: p.tempC,
                    humidity: rh,
                    pressure: p.pressHpa
                )
            )
        }
        return result
    }
    
    private struct Partial {
        var lat: Double
        var lon: Double
        var precip: Double?
        var soil: Double?
        var tempC: Double?
        var pressHpa: Double?
        var specHumidity: Double?
    }
    
    // Относительная влажность RH% из удельной влажности q (kg/kg), T (°C), P (hPa)
    // e = (q * P) / (0.622 + 0.378*q), e_s = 6.112 * exp((17.67*T)/(T+243.5)), RH% = 100 * e / e_s
    private func computeRelativeHumidityPercent(tempC: Double?, pressureHpa: Double?, specificHumidity: Double?) -> Double? {
        guard let tC = tempC, let pHpa = pressureHpa, let q = specificHumidity, q > 0 else { return nil }
        let e = (q * pHpa) / (0.622 + 0.378 * q) // hPa
        let es = 6.112 * exp((17.67 * tC) / (tC + 243.5))
        guard es > 0 else { return nil }
        let rh = max(0.0, min(100.0, 100.0 * e / es))
        return rh
    }
    
    // MARK: - NASA POWER fallback (open API)
    // Docs: https://power.larc.nasa.gov/docs/services/api/
    // Hourly point endpoint example:
    // https://power.larc.nasa.gov/api/temporal/hourly/point?parameters=T2M,RH2M,PS,PRECTOTCORR&community=AG&longitude=12.5&latitude=48.0&start=20250904&end=20251004&format=JSON
    private func fetchFromNASAPOWER(for coordinate: CLLocationCoordinate2D, days: Int) async throws -> [NASAHydrologyData] {
        let endDate = clampToPreviousHour(Date())
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        df.timeZone = .utc
        let start = df.string(from: startDate)
        let end = df.string(from: endDate)
        
        var comps = URLComponents(string: "https://power.larc.nasa.gov/api/temporal/hourly/point")!
        comps.queryItems = [
            URLQueryItem(name: "parameters", value: "T2M,RH2M,PS,PRECTOTCORR"),
            URLQueryItem(name: "community", value: "AG"),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "start", value: start),
            URLQueryItem(name: "end", value: end),
            URLQueryItem(name: "format", value: "JSON")
        ]
        let url = comps.url!
        
        if debugLogging {
            print("POWER Requesting: \(url.absoluteString)")
        }
        
        var request = URLRequest(url: url)
        request.setValue("CastorSky/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw TSSAPIError.invalidResponse(message: "POWER HTTP \(http.statusCode)", sample: previewSample(from: data))
        }
        
        let decoded = try decodePowerHourly(data)
        let series = mergePowerToHydrology(decoded, lat: coordinate.latitude, lon: coordinate.longitude)
        if debugLogging {
            print("POWER parsed items: \(series.count)")
        }
        return series
    }
    
    // POWER JSON models
    private struct PowerHourlyResponse: Decodable {
        let properties: PowerProperties
    }
    private struct PowerProperties: Decodable {
        let parameter: PowerParameter
    }
    private struct PowerParameter: Decodable {
        let T2M: [String: Double]?
        let RH2M: [String: Double]?
        let PS: [String: Double]?
        let PRECTOTCORR: [String: Double]?
    }
    
    private func decodePowerHourly(_ data: Data) throws -> PowerParameter {
        do {
            let decoder = JSONDecoder()
            let resp = try decoder.decode(PowerHourlyResponse.self, from: data)
            return resp.properties.parameter
        } catch {
            if debugLogging, let s = String(data: data, encoding: .utf8) {
                print("POWER decode failed. Sample: \(String(s.prefix(400)))")
            }
            throw TSSAPIError.decodingFailed
        }
    }
    
    // POWER timestamps keys formats: often "YYYYMMDDHH" or "YYYYMMDD:HH"
    private func parsePowerTimestamp(_ key: String) -> Date? {
        // Try YYYYMMDDHH
        let f1 = DateFormatter()
        f1.dateFormat = "yyyyMMddHH"
        f1.timeZone = .utc
        if let d = f1.date(from: key) { return d }
        // Try YYYYMMDD:HH
        let f2 = DateFormatter()
        f2.dateFormat = "yyyyMMdd:HH"
        f2.timeZone = .utc
        if let d = f2.date(from: key) { return d }
        // Try ISO hour "yyyy-MM-dd'T'HH"
        let f3 = DateFormatter()
        f3.dateFormat = "yyyy-MM-dd'T'HH"
        f3.timeZone = .utc
        if let d = f3.date(from: key) { return d }
        return nil
    }
    
    private func mergePowerToHydrology(_ param: PowerParameter, lat: Double, lon: Double) -> [NASAHydrologyData] {
        // Соберём все ключи времени
        var keys = Set<String>()
        if let k = param.T2M?.keys { keys.formUnion(k) }
        if let k = param.RH2M?.keys { keys.formUnion(k) }
        if let k = param.PS?.keys { keys.formUnion(k) }
        if let k = param.PRECTOTCORR?.keys { keys.formUnion(k) }
        
        var result: [NASAHydrologyData] = []
        for key in keys {
            guard let date = parsePowerTimestamp(key) else { continue }
            let t = param.T2M?[key] // °C
            let rh = param.RH2M?[key] // %
            let psRaw = param.PS?[key] // обычно kPa
            let pHpa: Double? = psRaw.flatMap { convertPowerPressureToHpa($0) }
            let pr = param.PRECTOTCORR?[key] // mm/hr
            
            let item = NASAHydrologyData(
                timestamp: date,
                latitude: lat,
                longitude: lon,
                precipitation: pr,
                soilMoisture: nil,            // POWER не отдаёт SM
                temperature: t,
                humidity: rh,
                pressure: pHpa
            )
            result.append(item)
        }
        return result.sorted { $0.timestamp < $1.timestamp }
    }
    
    // POWER PS -> hPa: по документации PS в kPa, значит *10 => hPa
    private func convertPowerPressureToHpa(_ ps: Double) -> Double {
        if ps < 200 { return ps * 10.0 }   // kPa -> hPa
        if ps > 2000 { return ps / 100.0 } // Pa  -> hPa
        return ps                           // уже hPa
    }
    
    // MARK: - Daily aggregation for precipitation screen (POWER)
    private func aggregatePrecipitationDailyFromPower(_ series: [NASAHydrologyData], coordinate: CLLocationCoordinate2D) -> [PrecipitationDataPoint] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .utc
        
        var daily: [String: Double] = [:]
        for item in series {
            guard let p = item.precipitation else { continue }
            let key = df.string(from: item.timestamp)
            daily[key, default: 0.0] += p
        }
        var result: [PrecipitationDataPoint] = []
        for (key, sum) in daily {
            if let d = df.date(from: key) {
                result.append(PrecipitationDataPoint(date: d, precipitation: sum, latitude: coordinate.latitude, longitude: coordinate.longitude))
            }
        }
        return result
    }

    // MARK: - Open‑Meteo fallback (ERA5 hourly)
    private struct OMHourlyResponse: Decodable {
        let hourly: OMHourly
    }
    private struct OMHourly: Decodable {
        let time: [String]
        let temperature_2m: [Double]?
        let relative_humidity_2m: [Double]?
        let surface_pressure: [Double]?
        let precipitation: [Double]?
    }
    
    private func fetchFromOpenMeteo(for coordinate: CLLocationCoordinate2D, days: Int) async throws -> [NASAHydrologyData] {
        let endDate = clampToPreviousHour(Date())
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .utc
        let start = df.string(from: startDate)
        let end = df.string(from: endDate)
        var comps = URLComponents(string: "https://archive-api.open-meteo.com/v1/era5")!
        comps.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "start_date", value: start),
            URLQueryItem(name: "end_date", value: end),
            URLQueryItem(name: "hourly", value: "temperature_2m,relative_humidity_2m,surface_pressure,precipitation"),
            URLQueryItem(name: "timezone", value: "UTC")
        ]
        let url = comps.url!
        if debugLogging { print("Open‑Meteo Requesting: \(url.absoluteString)") }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw TSSAPIError.invalidResponse(message: "Open‑Meteo HTTP \(http.statusCode)", sample: previewSample(from: data))
        }
        let decoded = try JSONDecoder().decode(OMHourlyResponse.self, from: data)
        let timeStrings = decoded.hourly.time
        let t = decoded.hourly.temperature_2m ?? Array(repeating: Double.nan, count: timeStrings.count)
        let rh = decoded.hourly.relative_humidity_2m ?? Array(repeating: Double.nan, count: timeStrings.count)
        let ps = decoded.hourly.surface_pressure ?? Array(repeating: Double.nan, count: timeStrings.count)
        let pr = decoded.hourly.precipitation ?? Array(repeating: Double.nan, count: timeStrings.count)
        
        let tf = DateFormatter()
        tf.dateFormat = "yyyy-MM-dd'T'HH:mm"
        tf.timeZone = .utc
        var result: [NASAHydrologyData] = []
        for (idx, ts) in timeStrings.enumerated() {
            guard let date = tf.date(from: ts) else { continue }
            let item = NASAHydrologyData(
                timestamp: date,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                precipitation: pr[idx].isNaN ? nil : pr[idx],
                soilMoisture: nil,
                temperature: t[idx].isNaN ? nil : t[idx],
                humidity: rh[idx].isNaN ? nil : rh[idx],
                pressure: ps[idx].isNaN ? nil : ps[idx]
            )
            result.append(item)
        }
        return result
    }
    
    private func aggregatePrecipitationDailyFromOpenMeteo(_ series: [NASAHydrologyData], coordinate: CLLocationCoordinate2D) -> [PrecipitationDataPoint] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .utc
        var daily: [String: Double] = [:]
        for item in series {
            guard let p = item.precipitation else { continue }
            let key = df.string(from: item.timestamp)
            daily[key, default: 0.0] += p
        }
        var result: [PrecipitationDataPoint] = []
        for (key, sum) in daily {
            if let d = df.date(from: key) {
                result.append(PrecipitationDataPoint(date: d, precipitation: sum, latitude: coordinate.latitude, longitude: coordinate.longitude))
            }
        }
        return result
    }

    // MARK: - Patch last N days with fallback if missing/invalid
    private func fillRecentDaysIfMissing(baseDaily: [PrecipitationDataPoint], coordinate: CLLocationCoordinate2D, recentDays: Int) async throws -> [PrecipitationDataPoint] {
        var byDay: [String: PrecipitationDataPoint] = [:]
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .utc
        for dp in baseDaily { byDay[df.string(from: dp.date)] = dp }
        let today = clampToPreviousHour(Date())
        let start = Calendar.current.date(byAdding: .day, value: -(recentDays-1), to: today) ?? today
        // Fetch Open‑Meteo for recent days only
        let omSeries = try await fetchFromOpenMeteo(for: coordinate, days: recentDays)
        let omDaily = aggregatePrecipitationDailyFromOpenMeteo(omSeries, coordinate: coordinate)
        let omByDay = Dictionary(uniqueKeysWithValues: omDaily.map { (df.string(from: $0.date), $0) })
        var out = baseDaily
        var changed = false
        var d = start
        while d <= today {
            let key = df.string(from: d)
            let current = byDay[key]
            let invalid = current == nil || current!.precipitation.isNaN || current!.precipitation < 0
            if invalid, let fallback = omByDay[key] {
                byDay[key] = fallback
                changed = true
            }
            d = Calendar.current.date(byAdding: .day, value: 1, to: d) ?? today.addingTimeInterval(86400)
        }
        if changed {
            out = Array(byDay.values)
        }
        return out
    }
    
    // MARK: - Helpers from previous section
    
    private func aggregatePrecipitationDaily(_ data: [TSSDatum], coordinate: CLLocationCoordinate2D) -> [PrecipitationDataPoint] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = .utc
        
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withColonSeparatorInTime]
        
        var daily: [String: Double] = [:]
        
        for item in data {
            let t: Date?
            if let d = iso.date(from: item.time) {
                t = d
            } else {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                f.timeZone = .utc
                t = f.date(from: item.time)
            }
            guard let date = t, let p = item.apcpsfc else { continue }
            let key = df.string(from: date)
            daily[key, default: 0.0] += p
        }
        
        var result: [PrecipitationDataPoint] = []
        for (key, sum) in daily {
            if let d = df.date(from: key) {
                result.append(PrecipitationDataPoint(date: d, precipitation: sum, latitude: coordinate.latitude, longitude: coordinate.longitude))
            }
        }
        return result.sorted { $0.date > $1.date }
    }
    
    private func makeRainyDays(from daily: [PrecipitationDataPoint]) -> [RainyDay] {
        daily.map { dp in
            let intensity = determineRainIntensity(dp.precipitation)
            return RainyDay(date: dp.date, precipitation: dp.precipitation, isRainy: dp.precipitation > 0.1, intensity: intensity)
        }
    }
    
    private func determineRainIntensity(_ precipitation: Double) -> RainyDay.RainIntensity {
        switch precipitation {
        case 0..<0.1: return .none
        case 0.1..<2.5: return .light
        case 2.5..<10.0: return .moderate
        case 10.0..<25.0: return .heavy
        default: return .extreme
        }
    }
}

// MARK: - Hydrology Data Extensions
extension NASAHydrologyData {
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, HH:mm"
        return formatter.string(from: timestamp)
    }
    
    var precipitationDescription: String {
        guard let precip = precipitation else { return "No data" }
        if precip < 0.1 {
            return "No rain"
        } else if precip < 2.5 {
            return "Light rain"
        } else if precip < 7.6 {
            return "Moderate rain"
        } else {
            return "Heavy rain"
        }
    }
    
    var soilMoistureDescription: String {
        guard let moisture = soilMoisture else { return "No data" }
        if moisture < 0.15 {
            return "Very dry"
        } else if moisture < 0.25 {
            return "Dry"
        } else if moisture < 0.35 {
            return "Normal"
        } else {
            return "Wet"
        }
    }
}

// MARK: - Date helpers
private extension TimeZone {
    static let utc = TimeZone(secondsFromGMT: 0)!
}
