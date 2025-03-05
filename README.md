# PiView - FilePi Mobile Client

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

PiView is a Flutter-based mobile application designed to work seamlessly with the [FilePi Server](https://github.com/renjuashokan/FilePi). It allows users to browse, stream, upload, and manage files hosted on the FilePi server directly from their mobile devices.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

PiView serves as a mobile client for the [FilePi Server](https://github.com/renjuashokan/FilePi), a lightweight file browser server designed for Raspberry Pi. With PiView, users can easily access and interact with their files and media hosted on the FilePi server.

Whether you're managing documents, streaming videos, or uploading new files, PiView provides an intuitive and user-friendly interface for all your file management needs.

---

## Features

- **File Browsing**: Navigate through directories and files hosted on the FilePi server.
- **Media Streaming**: Stream audio and video files directly from the server.
- **File Uploads**: Upload files from your mobile device to the FilePi server.
- **Responsive Design**: Optimized for both Android and iOS devices.
- **Secure Connection**: Communicates securely with the FilePi server.

---

## Prerequisites

Before using PiView, ensure that you have the following:

1. **FilePi Server**:
   - Set up and running the [FilePi Server](https://github.com/renjuashokan/FilePi) on your Raspberry Pi or another compatible device.
   - Ensure the server is accessible over your local network or the internet.

2. **Flutter Environment**:
   - Install Flutter SDK on your development machine. Refer to the official [Flutter Installation Guide](https://flutter.dev/docs/get-started/install).

3. **Mobile Device**:
   - An Android or iOS device to run the PiView app.

---

## Installation

### Option 1: Using Prebuilt APK/IPA (Coming Soon)
- Download the latest release from the [Releases](https://github.com/yourusername/PiView/releases) section.
- Install the APK (Android) or IPA (iOS) on your device.

### Option 2: Building from Source
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/renjuashokan/pi_view.git
   cd pi_view
   ```
2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Build the App**:
   - For Android:
     ```bash
     flutter build apk
     ```
   - For iOS: (coming soon)
     ```bash
     flutter build ios
     ```
4. **Run the App**:
   - Connect your device or start an emulator and run:
     ```bash
     flutter run
     ```
## Usage

1. Launch the PiView app on your mobile device.
2. Enter the IP address on the login screen
3. Browse, stream, and manage your files directly from the app.

## Contributing

We welcome contributions from the community! If you'd like to contribute to PiView, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bugfix:
   ```bash
   git checkout -b feat/your-feature-name
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add your commit message here"
   ```
4. Push your branch:
   ```bash
   git push origin feat/your-feature-name
   ```
5. Open a pull request in this repository.

For major changes, please open an issue first to discuss your proposed changes.

---

## License

This project is licensed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for details.