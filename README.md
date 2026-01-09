# Avatar POS

A modern, cross-platform Point of Sale (POS) system built with Flutter. Supports Android, iOS, Web, Windows, and macOS.

## 🏗️ Architecture

This project follows a **feature-first architecture** with clean separation of concerns:

### State Management

- **Riverpod** - Modern, compile-safe state management with code generation
- Providers are organized by feature for better modularity

### Routing

- **go_router** - Declarative routing with deep linking support
- Type-safe navigation across all platforms

### Code Generation

- **Freezed** - Immutable models with copyWith, equality, and serialization
- **json_serializable** - JSON serialization/deserialization
- **riverpod_generator** - Auto-generated providers

## 📁 Project Structure

```
lib/
├── core/                      # Core utilities and configurations
│   ├── constants/            # App-wide constants
│   ├── router/               # Routing configuration
│   ├── theme/                # Theme definitions
│   └── utils/                # Utility functions and extensions
├── features/                 # Feature modules
│   ├── home/                # Home/Dashboard feature
│   │   ├── models/          # Data models
│   │   ├── providers/       # State providers
│   │   ├── screens/         # UI screens
│   │   └── widgets/         # Feature-specific widgets
│   ├── products/            # Products management
│   ├── cart/                # Shopping cart
│   └── settings/            # App settings
└── shared/                  # Shared widgets and utilities
    └── widgets/             # Reusable widgets
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.8.1)
- Dart SDK (^3.8.1)

### Installation

1. **Clone the repository**

```bash
git clone <repository-url>
cd avatar_pos
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Run code generation**

```bash
dart run build_runner build --delete-conflicting-outputs
```

4. **Run the app**

```bash
# For development
flutter run

# For specific platform
flutter run -d chrome        # Web
flutter run -d macos         # macOS
flutter run -d windows       # Windows
flutter run -d android       # Android
flutter run -d ios           # iOS
```

## 🔧 Development

### Code Generation

When you modify models or providers with annotations, run:

```bash
# Watch mode (auto-regenerates on file changes)
dart run build_runner watch --delete-conflicting-outputs

# One-time build
dart run build_runner build --delete-conflicting-outputs
```

### Adding a New Feature

1. Create feature folder in `lib/features/`
2. Add models in `models/` with Freezed annotations
3. Create providers in `providers/` with Riverpod annotations
4. Build UI in `screens/` and `widgets/`
5. Add routes in `core/router/app_router.dart`
6. Run code generation

## 📦 Dependencies

### Production

- **flutter_riverpod** - State management
- **go_router** - Routing
- **freezed_annotation** - Code generation annotations
- **json_annotation** - JSON serialization
- **shared_preferences** - Local storage (cross-platform)
- **intl** - Internationalization
- **uuid** - Unique ID generation

### Development

- **build_runner** - Code generation runner
- **freezed** - Code generator for models
- **json_serializable** - JSON code generator
- **riverpod_generator** - Riverpod code generator
- **flutter_lints** - Linting rules

## 🌐 Cross-Platform Support

This app is designed to work seamlessly across:

- ✅ **Android** (Mobile & Tablet)
- ✅ **iOS** (iPhone & iPad)
- ✅ **Web** (Desktop & Mobile browsers)
- ✅ **Windows** (Desktop)
- ✅ **macOS** (Desktop)

All dependencies are carefully selected to ensure cross-platform compatibility.

## 🎨 Features

### Current

- ✅ Product catalog with grid view
- ✅ Shopping cart management
- ✅ Responsive UI (adapts to screen size)
- ✅ Cross-platform navigation
- ✅ Theme support (light/dark)

### Planned

- 🔲 Product CRUD operations
- 🔲 Transaction history
- 🔲 Receipt generation
- 🔲 Inventory management
- 🔲 User authentication
- 🔲 Payment integration
- 🔲 Barcode scanning
- 🔲 Reports and analytics

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📱 Platform-Specific Notes

### Web

- Uses IndexedDB for local storage via `shared_preferences`
- Responsive design adapts to mobile and desktop viewports

### Desktop (Windows/macOS)

- Native window chrome and menus
- Keyboard shortcuts supported

### Mobile (Android/iOS)

- Touch-optimized UI
- Native navigation patterns

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests and linting
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- Imam muhtadi - Initial work

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Riverpod for excellent state management
- Community contributors
