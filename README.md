Castor’s Sky ☔️
Answering the age-old question: "Will it rain on my parade?"
Castor’s Sky is a sophisticated iOS application that moves beyond simple weather forecasts. It combines live precipitation mapping with authoritative, long-term precipitation history from NASA, empowering users to make confident, data-driven decisions for any outdoor event.

<p align="center"> <img src="https://img.shields.io/badge/Swift-5.9-F05138.svg" alt="Swift"> <img src="https://img.shields.io/badge/iOS-17+-blue.svg" alt="iOS 17+"> <img src="https://img.shields.io/badge/UI-SwiftUI-orange.svg" alt="SwiftUI"> <img src="https://img.shields.io/badge/Data-NASA-informational.svg" alt="NASA Data"> </p>

<pre>
🛠️ Technical Highlights
</pre>
Castor’s Sky is built with a modern, robust iOS architecture:

Platform: iOS 17+
UI Framework: SwiftUI
Architecture: Async/Await, Combine
Map & Visualization: MapKit, Swift Charts
Core Innovation: NASAHydrologyManager

<pre>
Orchestrates all data calls with a primary focus on NASA Time Series Service (NLDAS/GLDAS).
Merges and processes hourly data, performing unit conversion (K→°C) and deriving metrics like relative humidity.
Implements a circuit breaker and multi-source fallback chain to guarantee data availability, seamlessly patching any gaps in the historical record.
</pre> 

Castor’s Sky is an iOS app that answers “Will it rain on my parade?” by combining a live, readable precipitation map with localized forecasts and NASA-based precipitation history. Built with SwiftUI and MapKit, it lets users tap the map or search any city to see a pulsating pin and a pull‑up card with current precipitation, temperature, wind, and a real 24‑hour precipitation chart. A dedicated Forecast page visualizes 7–90 days of daily precipitation and “rainy days” intensity using NASA Time Series (NLDAS/GLDAS) as the primary source. To ensure reliability, the app includes a resilient data pipeline with caching, retries, and automatic fallbacks to NASA POWER and Open‑Meteo ERA5—also patching the last three days if NASA data are missing—so charts never go blank. By merging authoritative science data with a clear, space‑themed UI and city‑level interaction, Castor’s Sky empowers citizens and event organizers to make quick, confident decisions about outdoor plans.


📸 Screenshots
(You can add screenshots of your app here)

[Image: Main Map View with precipitation overlay and pull-up card]
[Image: Forecast Page showing historical precipitation bar chart and rainy days grid]

<pre>
🔧 Installation
</pre>
Clone the repository:
bash
git clone https://github.com/your-username/castors-sky.git
Open CastorsSky.xcodeproj in Xcode 15 or later.
Ensure you are using an iOS 17+ simulator or device.
Build and run the project (⌘+R).

<pre>
🚀 Usage
</pre>
Launch the app to see the live precipitation map.
Tap any location on the map or use the search bar to find a city.
View the current conditions and 24-hour forecast in the pull-up card.
Navigate to the "Forecast" tab to explore the long-term precipitation history and rainfall intensity analysis.


Built with ❤️ using SwiftUI, MapKit, and the power of NASA science.
