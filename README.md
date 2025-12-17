# Plunge & Heat 🧊🔥

A beautiful iOS app for tracking cold plunge and sauna sessions with HealthKit integration, premium UI, and comprehensive analytics.

## Features

- **Quick Session Logging** - Log cold plunge or sauna sessions in seconds
- **Live Timer** - Built-in timer with haptic feedback and breathing guide
- **Health Integration** - Track HRV, heart rate, and sleep correlations
- **Beautiful Analytics** - Charts and progress tracking
- **Streak Tracking** - Stay motivated with daily streaks
- **Protocol Library** - Wim Hof, Huberman, and more
- **Goals & Achievements** - Personal goals and unlockable badges
- **Community Challenges** - Compete with others
- **Premium Features** - StoreKit 2 subscription support

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Clone the repository
2. Open `Plunge & Heat - Cold Plunge and Sauna Session Tracker.xcodeproj` in Xcode
3. Configure signing & capabilities (add HealthKit entitlement)
4. Build and run

## Project Structure

```
Plunge & Heat/
├── Design/          # Theme, colors, animations, components
├── Models/          # Session, Protocol, Goal data models
├── Services/        # Managers (Settings, Data, HealthKit, etc.)
└── Views/           # SwiftUI views organized by feature
    ├── Dashboard/   # Main logging interface
    ├── History/     # Calendar and session history
    ├── Insights/    # Analytics and health metrics
    ├── Onboarding/  # 5-screen welcome flow
    ├── Premium/     # Paywall and subscription
    └── Settings/    # User preferences
```

## Tech Stack

- SwiftUI
- HealthKit
- StoreKit 2
- Swift Charts
- PhotosUI

## License

MIT License
