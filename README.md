# AeraSync

AeraSync is a mobile and web application designed to streamline the calculation and tracking of the Standard Oxygen Transfer Rate (SOTR) and Standard Aeration Efficiency (SAE) for aerators in aquaculture ponds. The app provides a seamless interface for technicians to perform daily checkpointing, ensuring accurate and efficient monitoring of aeration performance. Future versions will incorporate AI-driven predictions to optimize aeration efficiency.

AeraSync is built using Dart and Flutter, enabling cross-platform support for mobile (Android, iOS) and web. The web version is hosted on GitHub Pages at [https://luisvinatea.github.io/AeraSync/](https://luisvinatea.github.io/AeraSync/).

## Features

- **SOTR & SAE Calculation** – Compute key aerator efficiency metrics effortlessly using a built-in calculator.
- **Cross-Platform Support** – Available on Android, iOS, and web, with a consistent user experience.
- **User-Friendly Interface** – Designed for field technicians with a simple and intuitive UI.
- **Localization** – Supports multiple languages (English, Spanish, Portuguese) for broader accessibility.
- **Data Integration** – Includes preloaded datasets (e.g., `o2_temp_sal_100_sat.json`) for accurate calculations.
- **Predictive Analytics (Upcoming)** – AI-driven insights for aeration optimization (planned for future releases).

## Installation

AeraSync is a Flutter project. Follow these steps to set up and run the application locally:

1. **Clone the Repository**:
   ```sh
   git clone https://github.com/luisvinatea/AeraSync.git
   ```
2. **Navigate to the Project Directory**:
   ```sh
   cd AeraSync
   ```
3. **Install Flutter Dependencies**:
   Ensure you have Flutter installed (see [Flutter installation guide](https://flutter.dev/docs/get-started/install)). Then, install the project dependencies:
   ```sh
   flutter pub get
   ```
4. **Run the Application**:
   - For web:
     ```sh
     flutter run -d chrome
     ```
   - For mobile (Android/iOS emulator or device):
     ```sh
     flutter run
     ```
   - To build a release version for web (e.g., for GitHub Pages):
     ```sh
     flutter build web --release
     ```

## Deployment to GitHub Pages

The web version of AeraSync is hosted on GitHub Pages. To deploy an updated version:

1. Build the web app:
   ```sh
   flutter build web --release
   ```
2. Copy the build output to the `gh-pages` branch (using a worktree or direct checkout):
   ```sh
   git worktree add ../AeraSync-gh-pages gh-pages
   cp -r build/web/* ../AeraSync-gh-pages/
   cd ../AeraSync-gh-pages
   git add .
   git commit -m "Update web deployment"
   git push origin gh-pages
   ```
3. Visit [https://luisvinatea.github.io/AeraSync/](https://luisvinatea.github.io/AeraSync/) to see the updated site.

## Tech Stack

- **Frontend & Cross-Platform**: Dart / Flutter
- **Backend (Future)**: Python (e.g., `sotr_calculator.py` for calculations, potential integration with Flask or Firebase)
- **Data Storage**: Local JSON files (e.g., `o2_temp_sal_100_sat.json`); future plans for cloud storage (Firestore/PostgreSQL)
- **Web Hosting**: GitHub Pages
- **AI Engine (Future)**: TensorFlow.js or PyTorch for predictive analytics

## Project Structure

```
AeraSync/
├── assets/                 # Static assets (e.g., JSON data)
├── lib/                    # Flutter source code
│   ├── core/               # Business logic (calculators, models, services)
│   ├── l10n/               # Localization files
│   ├── presentation/       # UI components (screens, widgets)
│   └── main.dart           # App entry point
├── web/                    # Web-specific files (index.html, manifest.json)
├── backend/                # Python scripts for calculations (e.g., sotr_calculator.py)
└── README.md
```

## Contribution

Contributions are welcome! Feel free to submit issues and pull requests. To contribute:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Make your changes and commit (`git commit -m "Add your feature"`).
4. Push to your branch (`git push origin feature/your-feature`).
5. Open a pull request.

## License

This project is licensed under the MIT License.

---

Made with ❤️ for the aquaculture industry.
