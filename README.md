# Crown Micro Solar

A Flutter application for managing and monitoring solar power systems.

## Project Structure

```
lib/
├── core/           # Core functionality, constants, and base classes
├── config/         # App configuration and environment variables
├── data/          # Data layer and models
├── model/         # Business logic models
├── repository/    # Data repositories
├── services/      # API and other services
├── utils/         # Utility functions and helpers
├── view/          # UI screens and pages
├── view_model/    # View models for MVVM pattern
├── widgets/       # Reusable widgets
├── routes/        # Route management
└── localization/  # Internationalization
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/crown-micro-solar.git
```

2. Navigate to the project directory:
```bash
cd crown-micro-solar
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Development Guidelines

- Follow the MVVM architecture pattern
- Write unit tests for business logic
- Use proper documentation for public APIs
- Follow Flutter's style guide
- Use meaningful commit messages

## Building for Production

```bash
flutter build apk --release  # For Android
flutter build ios --release  # For iOS
flutter build web --release  # For Web
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

