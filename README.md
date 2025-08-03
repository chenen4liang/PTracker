# PTracker - Period Tracker App

A simple, privacy-focused iOS period tracking app built with SwiftUI that stores all data locally on your device.

## Features

- **Circular Cycle View**: Visual representation of your current cycle with color-coded days
  - Red/Pink dots: Period days (1-7)
  - Gray dots: Past days in current cycle
  - White dots: Future days
  
- **Cycle History Chart**: Track cycle length variations over time
  - Interactive chart showing cycle lengths (20-40 day range)
  - Average cycle length indicator
  - Historical period data

- **Period Logging**: Easy period tracking with start/end dates
- **Notifications**: Reminders 3 days before and on expected period day
- **Cycle Predictions**: Based on your average cycle length
- **Data Export**: Export your data as CSV for backup or sharing
- **Bulk Import**: Import historical period data with one tap
- **Local Storage**: All data stored privately on device

## Screenshots

<img width="300" alt="Main View" src="https://github.com/user-attachments/assets/placeholder1">
<img width="300" alt="Chart View" src="https://github.com/user-attachments/assets/placeholder2">

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.0+

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/PTracker.git
cd PTracker
```

2. Open the project in Xcode:
```bash
open PTracker.xcodeproj
```

3. Build and run on your device or simulator

## Usage

### Adding a Period
1. Tap the **+** button to add a new period
2. Select the start date
3. Tap "Start Period" (end it later from the main screen)

### Importing Historical Data
- Tap the Import button (↓ icon) in the top-left
- The app includes sample historical data
- Modify `importManualData()` in ContentView.swift for custom data

### Exporting Data
1. Go to Settings (gear icon)
2. Tap "Export to CSV"
3. Save or share the file

## Privacy

PTracker is designed with privacy in mind:
- **100% Offline**: No internet connection required
- **No Cloud Sync**: All data stays on your device
- **No Analytics**: No tracking or data collection
- **No Accounts**: Start using immediately
- **Local Storage**: Uses iOS UserDefaults

## Project Structure

```
PTracker/
├── PTracker/
│   ├── PTrackerApp.swift        # App entry point
│   ├── ContentView.swift        # Main period list view
│   ├── AddPeriodView.swift      # Add/edit period view
│   ├── ChartView.swift          # Statistics and charts
│   ├── SettingsView.swift       # Settings and export
│   └── Assets.xcassets/         # App icons and assets
├── PTracker.xcodeproj/          # Xcode project files
├── README.md                    # This file
└── .gitignore                   # Git ignore file
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is available under the MIT License. See the LICENSE file for more info.

## Acknowledgments

Built with SwiftUI and ❤️ for privacy-conscious users.