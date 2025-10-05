//
//  CitySearchView.swift
//  Castor`s Sky
//
//  Created by Дадобоева_М on 04.10.2025.
//

import SwiftUI
import MapKit
import CoreLocation

struct CitySearchView: View {
    @Binding var isPresented: Bool
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedCityName: String?
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var searchError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for city or location", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            searchForLocation()
                        }
                        .onChange(of: searchText) { newValue in
                            if newValue.count > 2 {
                                searchForLocation()
                            } else {
                                searchResults = []
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.cyan.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Search Results
                if isSearching {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        Text("Searching...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if let error = searchError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Search Error")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "location.slash")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("No locations found")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Try a different search term")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    List(searchResults, id: \.self) { mapItem in
                        CitySearchResultRow(
                            mapItem: mapItem,
                            onTap: { coordinate, cityName in
                                selectedCoordinate = coordinate
                                selectedCityName = cityName
                                isPresented = false
                            }
                        )
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.11, blue: 0.23), Color(red: 0.02, green: 0.05, blue: 0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func searchForLocation() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        searchError = nil
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                if let error = error {
                    searchError = error.localizedDescription
                    return
                }
                
                searchResults = response?.mapItems ?? []
            }
        }
    }
}

struct CitySearchResultRow: View {
    let mapItem: MKMapItem
    let onTap: (CLLocationCoordinate2D, String) -> Void
    
    private var cityName: String {
        if let name = mapItem.name, !name.isEmpty {
            return name
        } else if let locality = mapItem.placemark.locality {
            return locality
        } else if let administrativeArea = mapItem.placemark.administrativeArea {
            return administrativeArea
        } else {
            return "Unknown Location"
        }
    }
    
    private var locationDescription: String {
        var components: [String] = []
        
        if let locality = mapItem.placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = mapItem.placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let country = mapItem.placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    var body: some View {
        Button(action: {
            onTap(mapItem.placemark.coordinate, cityName)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cityName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(locationDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "location")
                    .font(.title3)
                    .foregroundColor(.cyan)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CitySearchView(
        isPresented: .constant(true),
        selectedCoordinate: .constant(nil),
        selectedCityName: .constant(nil)
    )
}

