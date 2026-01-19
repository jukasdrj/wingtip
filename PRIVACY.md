# Privacy Policy for Wingtip

**Last Updated: January 19, 2026**

## Introduction

Wingtip is a local-first personal library manager designed with privacy as a core principle. This privacy policy explains what data we collect, how we use it, and your rights regarding your information.

## Our Privacy Commitment

**TL;DR: We don't know what books you own, and we never will.**

Wingtip is designed to minimize data collection and maximize user privacy. Your personal library data never leaves your device except during the book scanning process, and even then, we only receive anonymous image data.

## Data We Collect

### 1. Device Identifier (Required)
- **What:** A randomly generated UUID stored securely on your device
- **Why:** To prevent abuse of our AI scanning service (rate limiting)
- **Where:** Stored locally in iOS Keychain, sent with scan requests
- **Retention:** Persists on your device until app deletion
- **Can it identify you?** No. It's a random identifier with no personal information

### 2. Book Spine Images (Temporary, During Scanning Only)
- **What:** Photos of book spines you scan with the camera
- **Why:** To identify books using AI/machine learning
- **Where:** Uploaded to our Talaria backend service during scanning
- **Retention:** Deleted from our servers within 5 minutes after processing
- **Can it identify you?** No. We don't store images long-term or link them to accounts

### 3. Book Metadata (Local Only)
- **What:** Title, author, ISBN, cover images retrieved during scanning
- **Why:** To populate your personal library
- **Where:** Stored locally in SQLite database on your device only
- **Retention:** Remains on your device until you delete books or uninstall the app
- **Can it identify you?** No. This data never leaves your device

## Data We Do NOT Collect

- ❌ No user accounts (we don't even have a login system)
- ❌ No names, emails, phone numbers, or personal identifiers
- ❌ No location data or GPS coordinates
- ❌ No analytics or tracking (no Google Analytics, Firebase, etc.)
- ❌ No advertising IDs or third-party trackers
- ❌ No browsing history or app usage statistics
- ❌ No contact lists or photo library access (beyond camera permission)
- ❌ No social media integration or sharing
- ❌ No crash reports (unless you explicitly choose to send via iOS)

## How We Use Your Data

### Device Identifier
- Sent with each scan request to our Talaria backend
- Used solely for rate limiting (preventing abuse)
- Not stored in logs, not linked to any other data
- Not shared with third parties

### Book Spine Images
- Processed by our AI model to identify books
- Temporarily stored in memory during processing
- Automatically deleted within 5 minutes
- Not used for training models or any other purpose
- Not shared with third parties

### Book Metadata
- Stored locally on your device in SQLite
- Used only to display your library within the app
- Never uploaded to our servers or cloud storage
- You can export as CSV and delete anytime

## Third-Party Services

### Talaria Backend (Our Service)
- **Purpose:** AI-powered book identification during scanning
- **Data Sent:** Device UUID, book spine image
- **Data Retained:** None (images deleted after 5 minutes)
- **Location:** [Your server region, e.g., US-East]

### Book Cover Images
- **Source:** Third-party book databases (e.g., Open Library, Google Books)
- **Purpose:** Displaying book covers in your library
- **Privacy:** Cover URLs are fetched during scanning, cached locally
- **Direct requests:** Your device may directly request cover images from CDNs

### Google Fonts API
- **Purpose:** Loading Inter and JetBrains Mono fonts
- **Privacy:** Your device requests fonts from Google Fonts CDN
- **Data Sent:** Standard HTTP request headers (IP address, user agent)
- **Google's Policy:** [https://developers.google.com/fonts/faq/privacy](https://developers.google.com/fonts/faq/privacy)

## Data Storage and Security

### Local Storage
- All library data stored in encrypted SQLite database
- iOS Keychain used for secure device UUID storage
- Data encrypted at rest by iOS (device encryption)
- Only accessible by Wingtip app (sandboxed storage)

### Network Transmission
- All API requests use HTTPS (TLS 1.3)
- Images transmitted securely during scanning
- No man-in-the-middle attacks possible

### Server-Side Security
- Temporary image storage in memory only
- Automatic deletion after 5 minutes
- No long-term storage or backups of user data
- Rate limiting to prevent abuse

## Your Rights and Controls

### Data Access
- ✅ View all your library data directly in the app
- ✅ Export entire library as CSV anytime (Settings > Export CSV)
- ✅ No login required to access your own data

### Data Deletion
- ✅ Delete individual books from your library
- ✅ Delete entire library by uninstalling the app
- ✅ Clear all data via iOS Settings > Wingtip > Reset

### Data Portability
- ✅ Export library as CSV (standard format)
- ✅ Book metadata is not locked into Wingtip
- ✅ Take your data anywhere

### Opt-Out
- ✅ Don't want to scan books? Use Wingtip offline-only (manual entry via CSV import)
- ✅ Concerned about rate limiting? Device UUID is only sent during scanning

## Children's Privacy

Wingtip does not knowingly collect any data from children under 13. The app has a 4+ age rating and does not contain objectionable content. Since we don't collect personal information, COPPA compliance is inherent.

## Changes to This Privacy Policy

We may update this privacy policy from time to time. Changes will be reflected by updating the "Last Updated" date at the top of this policy. Continued use of Wingtip after changes constitutes acceptance of the updated policy.

Significant changes will be communicated via:
- App Store release notes
- In-app notification (if technically feasible)
- GitHub repository announcement

## Open Source Transparency

Wingtip is open source. You can review the code to verify our privacy claims:
- GitHub: [https://github.com/yourusername/wingtip](https://github.com/yourusername/wingtip)
- License: [Your license, e.g., MIT]

Our code demonstrates:
- No analytics SDKs integrated
- No tracking code present
- Local-first SQLite storage
- Minimal network requests (scan-only)

## Contact Us

If you have questions about this privacy policy or data practices:

- **Email:** [your-email@example.com]
- **GitHub Issues:** [https://github.com/yourusername/wingtip/issues](https://github.com/yourusername/wingtip/issues)
- **Response Time:** We aim to respond within 5 business days

## Legal Compliance

### GDPR (EU Users)
- **Lawful Basis:** Legitimate interest (providing book scanning service)
- **Data Minimization:** We collect only what's necessary
- **Right to Erasure:** Uninstall app to delete all local data
- **Data Portability:** Export as CSV anytime

### CCPA (California Users)
- **No Sale of Data:** We do not sell personal information
- **No Sharing:** We do not share data with third parties for marketing
- **Access Rights:** Export your library as CSV
- **Deletion Rights:** Uninstall app or delete books individually

### App Store Privacy Labels

When you view Wingtip on the App Store, you'll see our privacy label:

**Data Used to Track You:** None

**Data Linked to You:** None

**Data Not Linked to You:**
- User Content (book spine images, temporary)
- Identifiers (device UUID, for rate limiting only)

## Summary

Wingtip is designed to respect your privacy:

1. **Local-first:** Your library data stays on your device
2. **No accounts:** No login, no passwords, no user profiles
3. **No tracking:** Zero analytics, zero advertising
4. **Minimal collection:** Only what's needed for scanning (device UUID + image)
5. **Temporary storage:** Images deleted within 5 minutes
6. **Full control:** Export or delete your data anytime
7. **Open source:** Verify our claims by reading the code

**Questions?** Open an issue on GitHub or email us. We're happy to clarify our privacy practices.

---

**Wingtip** - Swiss design, zero tracking.
