# Wingtip Support

Welcome to Wingtip support! This document provides help for common issues, frequently asked questions, and contact information.

## Quick Links

- **Privacy Policy:** [PRIVACY.md](PRIVACY.md)
- **GitHub Repository:** [https://github.com/yourusername/wingtip](https://github.com/yourusername/wingtip)
- **Report Issues:** [GitHub Issues](https://github.com/yourusername/wingtip/issues)
- **Email Support:** [your-email@example.com]

## Frequently Asked Questions

### Getting Started

**Q: How do I scan a book?**
A: Open Wingtip, point your camera at a book spine, and tap the orange shutter button. The AI will identify the book and add it to your library automatically.

**Q: Does Wingtip require an internet connection?**
A: Only for scanning new books. Viewing, searching, and managing your library works completely offline.

**Q: How many books can I scan?**
A: There's no hard limit. Your library is stored locally on your device, so capacity depends on your available storage.

**Q: Can I use Wingtip without scanning?**
A: Yes! You can manually import books via CSV or add them manually (if manual entry is implemented).

### Scanning Issues

**Q: The app says "Rate Limit Reached." What do I do?**
A: This means you've scanned too many books in a short time. Wait for the countdown timer to finish, then try again. This prevents abuse of our AI service.

**Q: Why isn't my book being recognized?**
A: Common reasons:
- Book spine is blurry or out of focus
- Poor lighting (try natural light or bright indoor lighting)
- Spine text is too small or obscured
- Book is very old or rare (not in our databases)

Try these fixes:
- Clean your camera lens
- Hold the phone steady
- Get closer to the spine (fill the frame)
- Ensure good lighting

**Q: What if a book is identified incorrectly?**
A: You can manually edit book details in the detail view, or delete and re-scan. If this happens frequently, please report it on GitHub with a photo of the spine.

**Q: Can I scan barcodes instead of spines?**
A: Not currently. Wingtip focuses on spine recognition for a faster workflow (no need to remove books from the shelf).

### Library Management

**Q: How do I search my library?**
A: Tap the search icon in the library view. You can search by title, author, or ISBN. Search is instant and works offline.

**Q: How do I delete a book?**
A: Open the book detail view and tap the delete button (trash icon). Confirm deletion. This only removes it from your local library.

**Q: Can I sort my library?**
A: Yes! Use the sort options in the library view (e.g., by title, author, date added).

**Q: How do I export my library?**
A: Go to Settings > Export CSV. Your library will be saved as a CSV file that you can share, backup, or import into other apps.

**Q: What format is the CSV export?**
A: Standard CSV with columns: ISBN, Title, Author, Format, Added Date, Spine Confidence, Review Needed.

### Privacy & Data

**Q: Where is my data stored?**
A: All your library data is stored locally on your device in a SQLite database. It never leaves your device except during scanning (when book spine images are sent to our AI service and deleted within 5 minutes).

**Q: Does Wingtip track my reading habits?**
A: No. Wingtip has zero analytics, zero tracking, zero data collection beyond what's needed for scanning.

**Q: Can I sync my library across devices?**
A: Not currently. Wingtip is local-first, meaning each device has its own library. You can export from one device and import to another via CSV.

**Q: What happens to my data if I uninstall Wingtip?**
A: All local data is deleted. If you want to keep your library, export as CSV before uninstalling.

**Q: Who can see my book list?**
A: Only you. Your library never leaves your device (except as a CSV if you choose to share it).

### Technical Issues

**Q: The app crashes when I open the camera.**
A: Grant camera permission in iOS Settings > Wingtip > Camera. If already granted, try restarting the app or your device.

**Q: Book covers aren't loading.**
A: This requires an internet connection. Cover images are fetched from third-party book databases. Check your network connection.

**Q: The app is slow or laggy.**
A: Try these steps:
1. Close and restart the app
2. Restart your iPhone
3. Check available storage (Settings > General > iPhone Storage)
4. If you have 1000+ books, consider exporting and archiving older entries

**Q: Search results are missing books I know I added.**
A: Full-text search requires the data to be indexed. Try closing and reopening the app. If the issue persists, report it on GitHub.

**Q: How do I reset the app?**
A: Go to iOS Settings > Wingtip > Reset (if available) or uninstall and reinstall the app. Note: This deletes all your library data.

### Device Compatibility

**Q: What iOS version do I need?**
A: iOS [minimum version, e.g., 14.0] or later. Optimized for iOS 17+.

**Q: Does Wingtip work on iPad?**
A: Yes, but it's designed for iPhone. iPad support is functional but not optimized.

**Q: Does Wingtip support Android?**
A: Not yet. Wingtip is iOS-first. Android support may come in the future.

**Q: Does Wingtip work on Apple Silicon Macs?**
A: Yes, via iOS app compatibility, but camera scanning won't work. You'd need to import via CSV.

### Feature Requests

**Q: Can you add [feature]?**
A: We welcome feature requests! Open an issue on GitHub with the label "enhancement" and describe your use case.

**Q: Will Wingtip support ebooks (EPUB, PDF)?**
A: Not currently. Wingtip focuses on physical books. Ebook support is a potential future enhancement.

**Q: Can Wingtip track reading progress?**
A: Not currently. Wingtip is a cataloging tool, not a reading tracker. This may be added in the future.

**Q: Can I add custom tags or categories?**
A: Not yet, but this is a commonly requested feature. Star the GitHub issue to vote for it.

## Troubleshooting Guide

### Camera Permission Issues
1. Open iOS Settings
2. Scroll to Wingtip
3. Tap "Camera"
4. Ensure "Allow Access to Camera" is enabled
5. Restart Wingtip

### Network Connection Issues
1. Check Wi-Fi or cellular data is enabled
2. Try scanning on a different network
3. Verify you're not in Airplane Mode
4. Check if other apps can access the internet

### Performance Issues
1. Close background apps
2. Restart Wingtip
3. Restart your iPhone
4. Check available storage (need at least 1 GB free)
5. Update to the latest iOS version

### Database Corruption
If your library data becomes corrupted:
1. Export your library as CSV (if possible)
2. Uninstall Wingtip
3. Reinstall from App Store
4. Import your library from CSV (if manual import is supported)

## Reporting Bugs

Found a bug? We want to know!

### Before Reporting
1. Check if the issue is already reported on GitHub Issues
2. Try reproducing the bug after restarting the app
3. Update to the latest version of Wingtip

### What to Include
- **iOS version** (e.g., iOS 17.2)
- **Device model** (e.g., iPhone 15 Pro)
- **Wingtip version** (Settings > About)
- **Steps to reproduce** (detailed)
- **Expected behavior** vs. **actual behavior**
- **Screenshots or screen recording** (if applicable)
- **Error messages** (if any)

### Where to Report
- **GitHub Issues:** [https://github.com/yourusername/wingtip/issues](https://github.com/yourusername/wingtip/issues)
- **Email:** [your-email@example.com] (if you prefer private reporting)

### Response Time
We aim to respond to bug reports within 5 business days. Critical bugs (crashes, data loss) are prioritized.

## Feature Requests

Have an idea for Wingtip? We'd love to hear it!

### How to Submit
1. Check if the feature is already requested on GitHub Issues
2. Open a new issue with the label "enhancement"
3. Describe the feature and your use case
4. Explain why it would benefit users

### Popular Requested Features
- Cloud sync across devices
- Manual book entry
- Reading progress tracking
- Custom tags and collections
- Barcode scanning
- Multiple sort options
- Dark/light mode toggle (currently OLED black only)
- Export to other formats (JSON, XML)

Vote for features by adding a 👍 reaction to the GitHub issue.

## Contact Us

### Email Support
**Email:** [your-email@example.com]
**Response Time:** 5 business days

### GitHub
**Repository:** [https://github.com/yourusername/wingtip](https://github.com/yourusername/wingtip)
**Issues:** [https://github.com/yourusername/wingtip/issues](https://github.com/yourusername/wingtip/issues)

### Social Media
- **Twitter/X:** [@wingtip_app] (if applicable)
- **Mastodon:** [@wingtip@mastodon.social] (if applicable)

## Contributing

Wingtip is open source! Contributions are welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) (if exists) for detailed guidelines.

## Acknowledgments

Wingtip is built with:
- Flutter & Dart
- Drift (SQLite ORM)
- Riverpod (state management)
- Google Fonts (Inter, JetBrains Mono)
- Talaria AI backend (book identification)

Special thanks to the open-source community and all contributors.

## Legal

- **Privacy Policy:** [PRIVACY.md](PRIVACY.md)
- **License:** [Your license, e.g., MIT] - [LICENSE](LICENSE)
- **Terms of Service:** By using Wingtip, you agree to use the app responsibly and not abuse our AI scanning service.

---

**Wingtip** - Swiss design, zero tracking.

*Need more help? Open an issue on GitHub or email us. We're here to help!*
