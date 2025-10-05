Castor’s Sky ☔️
Answering the age-old question: "Will it rain on my parade?"

Castor's Sky is a sophisticated iOS application that moves beyond simple weather forecasts. It combines live precipitation mapping with authoritative, long-term precipitation history from NASA, empowering users to make confident, data-driven decisions for any outdoor event.

<p align="center"> <img src="https://img.shields.io/badge/Swift-5.9-F05138.svg" alt="Swift"> <img src="https://img.shields.io/badge/iOS-17+-blue.svg" alt="iOS 17+"> <img src="https://img.shields.io/badge/UI-SwiftUI-orange.svg" alt="SwiftUI"> <img src="https://img.shields.io/badge/Data-NASA-informational.svg" alt="NASA Data"> </p>
✨ Features
Interactive Live Map - Tap anywhere on the MapKit-based map or search for any city to view current precipitation, temperature, wind, and a 24-hour forecast chart

Long-Term Rain Analysis - Get detailed historical view of daily precipitation and "rainy day" intensity for the past 7 to 90 days, sourced directly from NASA's hydrology services

Resilient Data Pipeline - Intelligent caching, exponential backoff retries, and automatic fallback system (NASA POWER → Open-Meteo ERA5) to ensure data is always available

Event Planning Focus - Specifically designed to reduce the risk and anxiety of planning outdoor gatherings

🛠️ Technical Highlights
Architecture & Technologies:

Platform: iOS 17+

UI Framework: SwiftUI

Architecture: Async/Await, Combine

Map & Visualization: MapKit, Swift Charts

Core Innovation - NASAHydrologyManager:

Orchestrates all data calls with primary focus on NASA Time Series Service (NLDAS/GLDAS)

Merges and processes hourly data, performing unit conversion (K→°C) and deriving metrics like relative humidity

Implements circuit breaker and multi-source fallback chain to guarantee data availability

Seamlessly patches gaps in historical record using automatic fallback sources

📸 Screenshots
(You can add screenshots of your app here)

[Image: Main Map View with precipitation overlay and pull-up card]
[Image: Forecast Page showing historical precipitation bar chart and rainy days grid]

🔧 Installation
Clone the repository:
bash
git clone https://github.com/your-username/castors-sky.git
Open CastorsSky.xcodeproj in Xcode 15 or later
Ensure you are using an iOS 17+ simulator or device
Build and run the project (⌘+R)

🚀 Usage
Launch the app to see the live precipitation map
Tap any location on the map or use the search bar to find a city
View the current conditions and 24-hour forecast in the pull-up card
Navigate to the "Forecast" tab to explore long-term precipitation history and rainfall intensity analysis

Built with ❤️ using SwiftUI, MapKit, and the power of NASA science.
