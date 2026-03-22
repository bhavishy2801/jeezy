<div align="center">
  <img src="assets/images/jeezy.jpg" width="200" alt="JEEzy logo">
  <br>
  <h1>JEEzy</h1>
</div>

[![Flutter](https://img.shields.io/badge/Flutter-%5E3.7.2-02569B?logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/backend-Firebase-FFCA28?logo=firebase)](https://firebase.google.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()

JEEzy is a comprehensive cross-platform educational application built with Flutter. It aims to streamline the learning and reviewing process by combining document viewing, rich note-taking, interactive testing, and an AI-powered study assistant into a single, cohesive experience.

## Why JEEzy is Useful

JEEzy solves the problem of app-switching during study sessions by consolidating essential academic tools into a unified platform. 

**Key Features:**
- **AI Assistant:** Built-in Gemini AI integration to answer questions, summarize texts, and guide learning.
- **Comprehensive Note-Taking:** Create, organize, and bookmark rich notes directly next to your study material.
- **Integrated Office & PDF Viewers:** Open, read, and annotate standard document formats natively without leaving the app.
- **Interactive Tests & Progress Tracking:** Take quizzes, review answers, and track your learning progress with intuitive charts.
- **Firebase Synchronization:** Seamlessly sync auth states, bookmarks, and user profiles across your devices using Firebase backend services.

## Getting Started

### Prerequisites

To build and run this project, make sure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.7.2 or higher)
- [Dart SDK](https://dart.dev/get-dart)
- IDE of choice (VS Code, Android Studio, or IntelliJ IDEA) with Flutter extensions.

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/bhavishy2801/JEEzy.git
   cd JEEzy
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase & Gemini Environments:**
   - Follow the [Firebase setup guide for Flutter](https://firebase.google.com/docs/flutter/setup) to generate your `google-services.json` and `GoogleService-Info.plist` files, placing them in their respective platform directories.
   - Configure your Gemini API keys securely via environment variables or a configuration class to enable the AI assistant functionality.

4. **Run the App:**
   ```bash
   flutter run
   ```

## Where to Get Help

If you encounter issues or have questions about how to use JEEzy:
- **Search Issue Tracker:** Check the [GitHub Issues](https://github.com/bhavishy2801/JEEzy/issues) on this repository.
- **Create a New Issue:** Use issue templates to report bugs or request features.
- **Discussions:** Feel free to open a thread on the Discussions tab (if enabled) for general queries.
- For issues specifically regarding Flutter framework bugs, please consult the [Flutter documentation](https://docs.flutter.dev/).

## Maintainers & Contributing

JEEzy is actively maintained by **[bhavishy2801](https://github.com/bhavishy2801)** and the open-source community.

We welcome all contributions—from bug fixes, layout improvements, to completely new features! Before submitting pull requests, please read our detailed guidelines located in `docs/CONTRIBUTING.md` (if available) to ensure a smooth collaboration process.

---
_A fully featured learning dashboard powered by Flutter, AI, and Firebase._