![Visitor Count](https://visitor-badge.laobi.icu/badge?page_id=thechampusman.primewintools)



# PrimeWinTools

PrimeWinTools is a versatile utility for Windows users, combining powerful clipboard management with system cleanup features. Whether you're a power user who frequently handles large amounts of copied content or someone looking to optimize your system performance by cleaning unnecessary files, PrimeWinTools makes it simple and efficient.

---

## 📸 Screenshots

<div align="center">
  <img src="assets/ss/web.png" alt="Main Dashboard" width="80%" style="margin: 10px;">
</div>

### Main Application Views
<div align="center">
  <img src="assets/ss/1.png" alt="Main Dashboard" width="45%" style="margin: 10px;">
</div>

<div align="center">
  <img src="assets/ss/2.png" alt="Application Overview" width="45%" style="margin: 10px;">
</div>

<div align="center">
  <img src="assets/ss/3.png" alt="User Interface" width="45%" style="margin: 10px;">
</div>

<div align="center">
  <img src="assets/ss/4.png" alt="Settings & Features" width="45%" style="margin: 10px;">
</div>

### Feature-Specific Views
<div align="center">
  <img src="assets/ss/clipboard.png" alt="Clipboard Manager" width="80%" style="margin: 10px;">
</div>

<div align="center">
  <img src="assets/ss/system clear.png" alt="System Cleaner" width="80%" style="margin: 10px;">
</div>

<div align="center">
  <img src="assets/ss/localhost.png" alt="Localhost Manager" width="80%" style="margin: 10px;">
</div>

<div align="center">
  <img src="assets/ss/about.png" alt="About Page" width="80%" style="margin: 10px;">
</div>

---

## 🔥 Key Features

### 1. Clipboard Manager:
- Stores and manages clipboard history for up to 20 days.
- Easily retrieve, search, and delete previous clipboard entries.
- Avoid losing important copied data with clipboard tracking.
- Designed for professionals and power users who frequently copy text, files, and images.

### 2. System Cleaner:
- Cleans system directories like **Prefetch**, **Temp**, and **%TEMP%** to free up disk space.
- Helps to improve overall system performance by removing unnecessary temporary files.
- **Log history** feature to track past cleanup operations for transparency.

### 3. Localhost Manager:
- Real-time monitoring of active localhost ports and services.
- Automatic detection of running processes and their associated ports.
- Service identification for common development frameworks (React, Node.js, Angular, etc.).
- Quick access to open services in browser or copy URLs to clipboard.
- Advanced port scanning with process identification and PID tracking.

### What's New (Network Access & UX improvements)
- LAN network URL: each detected localhost service now shows a network-accessible URL (http://<your-ip>:<port>) when your machine has a non-loopback IPv4 address. This makes it easy for devices on the same local network to reach a development server running on your machine.
- Clickable network URL: the displayed network URL is clickable — it opens in the default browser and also supports copying to the clipboard.
- Copy network URL: a dedicated "Copy network URL" action copies the full network URL to the clipboard and shows a toast/snackbar confirmation.
- QR code dialog: a "Show QR" action opens a dialog containing a QR code for the network URL so mobile devices can scan and open the service quickly. The app falls back to showing the raw URL if QR generation is unavailable.
- Responsive actions & overflow menu: action buttons in the Localhost Manager adapt to narrow window widths; when space is limited the less-used actions are moved into a three-dot overflow menu to avoid layout issues.
- IP detection: the app attempts to detect your primary non-loopback IPv4 address on startup and when the Localhost tab is opened. If no LAN IP is available, the network actions are hidden and the UI displays "No LAN IP".

### 4. User-Friendly Interface:
- Clean and simple UI like Acrylic material blur for ease of use and look appealing.
- Efficient background operation without interrupting your workflow.
- Built with Flutter, ensuring a smooth native Windows experience.

---

## � QR Generator & Python Environments (Advanced / Optional)

### QR Generator (optional)
- Location: `scripts/qr_generator.py` — a small Python helper used by the app to generate QR codes on demand.
- Dependencies: the script uses the `qrcode` and `Pillow` Python packages. If those packages are not installed, the app will gracefully fall back and display the raw network URL.
- Install (one-time, system or virtualenv):

  - Using the script's installer flag (recommended):

    ```powershell
    python scripts\qr_generator.py --install
    ```

  - Or manually with pip:

    ```powershell
    pip install "qrcode[pil]" Pillow
    ```

- Notes:
  - Ensure a Python 3 interpreter is available on the system PATH so the Flutter app can call the script.
  - The app requests a base64 image from the script; if generation fails the UI shows the URL text so you can still copy/scan it manually.

### Python Environment Manager
- Purpose: helps detect, list, and cache discovered Python virtual environments and interpreters on the host machine (useful when developing or running Python-backed features).
- Cache: environment metadata is cached to speed up subsequent loads. Cache file: `cache/python_environments.json` (located in the app working directory). The UI exposes a cache info dialog and an option to clear the cache.
- Validation: cached environments are validated by checking for common activation scripts in the environment folder, including:
  - `Scripts\activate.ps1`
  - `Scripts\activate.bat`
  - `bin/activate`
- Actions in UI:
  - Scan for environments (configurable paths), refresh and validate results.
  - View cached environments and metadata (Python version, package count, last used).
  - Clear the environment cache to force a fresh scan.

---

---

## �🚀 Getting Started

### Installation:

1. Download the latest release from the [Releases]([https://github.com/thechampusman/PrimeWinTools/releases]) section.
2. Run the installer and follow the on-screen instructions.

### Requirements:
- **Operating System**: Windows 10 or later
- **Flutter SDK**: Required for contributors who want to build or modify the project.

---

## 🛠️ How to Use

### Clipboard Manager:
1. Launch PrimeWinTools.
2. The clipboard manager will automatically track and store your clipboard history for the past 20 days.
3. Use the UI to view, search, or delete specific clipboard entries.

### System Cleaner:
1. Go to the **System Cleaner** tab.
2. Click "Clean" to remove unnecessary files from key system directories.
3. Check the log history to track past cleanups.

### Localhost Manager:
1. Navigate to the **Localhost** tab.
2. Click "Refresh" to scan for active localhost ports and services.
3. View detailed information about each port including process name, PID, and service type.
4. Use the action buttons to open services in browser or copy URLs to clipboard. When a LAN IP is detected, an additional network URL is shown under the port which can be opened, copied, or shared via QR.
5. On narrow windows the extra actions will be available under the three-dot overflow menu (⋮).
5. Monitor development servers and identify what's running on each port.

---

## 📜 License

PrimeWinTools is licensed under a **custom proprietary license**. You are allowed to contribute to the project by submitting pull requests or patches, but the following restrictions apply:
- You may **not copy**, redistribute, or create new distributions, forks, or versions of this software without explicit written permission from the copyright holder.
- You may **not sublicense, sell, or transfer** this software in any way without permission.

For more details, please see the [LICENSE](./LICENSE.txt) file.

---

## 💻 Contributing

We welcome contributions from the community! Here’s how you can help:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a pull request.

Please ensure your changes follow the contribution guidelines and licensing terms.

---

## 🌟 Features Roadmap

- Add support for more system cleanup options.
- Introduce a customizable clipboard retention period.
- UI enhancements and additional customization features.

---

## 🤝 Support

If you encounter any issues or have any questions, feel free to open an issue on GitHub or contact us via [Your Email].

---

## 📊 Logs & Privacy

PrimeWinTools does not collect or transmit any personal data. All logs related to system cleanups are stored locally for user reference and transparency.

---

## 📜 Acknowledgments

- Built with Flutter for a native experience on Windows.
- Thank you to all contributors who have helped improve this project.

---

Enjoy using **PrimeWinTools** to optimize your clipboard and system performance!


