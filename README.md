Castor’s Sky ☔️
Answering the age-old question: "Will it rain on my parade?"
Castor’s Sky is a sophisticated iOS application that moves beyond simple weather forecasts. It combines live precipitation mapping with authoritative, long-term precipitation history from NASA, empowering users to make confident, data-driven decisions for any outdoor event.

<p align="center"> <img src="https://img.shields.io/badge/Swift-5.9-F05138.svg" alt="Swift"> <img src="https://img.shields.io/badge/iOS-17+-blue.svg" alt="iOS 17+"> <img src="https://img.shields.io/badge/UI-SwiftUI-orange.svg" alt="SwiftUI"> <img src="https://img.shields.io/badge/Data-NASA-informational.svg" alt="NASA Data"> </p>

## 📹 Демо (click)

[![Watch the demo](https://img.youtube.com/vi/a89cGJAaxHk/0.jpg)](https://youtu.be/a89cGJAaxHk)       


<pre>
🛠️ Technical Highlights
</pre>
Castor’s Sky is built with a modern, robust iOS architecture:     
Platform: iOS 17+    
UI Framework: SwiftUI    
Architecture: Async/Await, Combine    
Map & Visualization: MapKit, Swift Charts     
Core Innovation: NASAHydrologyManager        
     
Orchestrates all data calls with a primary focus on NASA Time Series Service (NLDAS/GLDAS).     
Merges and processes hourly data, performing unit conversion (K→°C) and deriving metrics like relative humidity.     
Implements a circuit breaker and multi-source fallback chain to guarantee data availability, seamlessly patching any gaps in the historical record.   

<pre>
🔧 Installation
</pre>
Clone the repository:     
bash git clone https://github.com/your-username/castors-sky.git     
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
