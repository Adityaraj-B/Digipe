# DIGIPe: India's Premier Solar Insurance Platform

DIGIPe is a high-fidelity, production-ready Flutter application designed to revolutionize the solar insurance industry in India. It provides a seamless, secure, and end-to-end digital journey for solar asset owners to protect their investments against accidental damage, theft, and natural calamities.

## 🚀 Core Features & Functionality

### 1. Dynamic Insurance Catalog
- **Multi-Product Support**: Real-time fetching of insurance products (Solar Panels, Inverters, etc.) from the backend.
- **Smart Pricing**: Instant calculation of "Starting at" prices based on minimum available plan premiums.
- **Rich Media**: Integration with `cached_network_image` for high-performance visual asset delivery.

### 2. Intelligent Application Flow
- **Auto-Persistence**: Leverages `flutter_secure_storage` to automatically save form progress. Users can exit and return to find their details (Address, Solar Specs) exactly where they left off.
- **Cascading Selection**: Implementation of a custom State -> City mapping (via `location_data.dart`) with alphabetical sorting and crash-proof validation.
- **Document Management**: Integrated `image_picker` and `file_picker` for uploading Invoices, Site Photos, and Videos with size validation (<10MB for images, <100MB for video).

### 3. Secure Payment Infrastructure
- **Cashfree Integration**: Professional integration with the `flutter_cashfree_pg_sdk` (v2.4.0+52) in **Production Mode**.
- **Biometric Gate**: Mandatory local authentication (FaceID/Fingerprint) via `local_auth` before any financial transaction is initiated.
- **Two-Tier Resolution**: A sophisticated `PaymentResolutionService` that handles edge cases where payment sessions might time out, ensuring internal order consistency.

### 4. Real-Time Order Tracking
- **Lifecycle Visualization**: A sophisticated, step-by-step progress tracker (Order Placed → Payment → Review → Issued).
- **Status Mapping**: Dynamic mapping of backend states (SUBMITTED, UNDER_REVIEW, APPROVED) to intuitive user labels.
- **Quick Actions**: One-tap access to download policy documents, view invoices, or raise claims directly from the tracking dashboard.

### 5. Advanced Claims Center
- **Digital Filing**: Field-for-field parity with industry standards for damage reporting (Date of Damage, Type, Evidence).
- **Evidence Vault**: Supports up to 5 high-resolution photos and optional video evidence for faster claim settlement.
- **Trackable History**: A dedicated view to monitor the progress of submitted claims (Pending, Approved, Settled, Rejected).

---

## 🛠 Tech Stack & Architecture

### Frontend
- **Framework**: Flutter 3.x (Latest Stable)
- **State Management**: `flutter_bloc` (v8.1.5) for predictable, event-driven state transitions.
- **Dependency Injection**: `get_it` for global service discovery (API, Auth, Notifications).
- **Navigation**: `go_router` for robust, declarative routing.

### Networking & Security
- **HTTP Client**: `dio` (v5.4.3) with specialized interceptors for JWT injection and 401/403 auto-handling.
- **Storage**: `flutter_secure_storage` for sensitive data (JWT, Profile Metadata) and `shared_preferences` for non-sensitive local flags.
- **Hardening**: 
  - `screen_protector`: Prevents screenshots and screen recording on sensitive insurance detail and payment screens.
  - `safe_device`: Blocks app execution on rooted, jailbroken, or non-physical devices in release mode.
  - `FlutterFragmentActivity`: Custom Android implementation to support native biometric prompts.

### Sensory & Feedback
- **Notifications**: `flutter_local_notifications` (v22+) with cross-platform permission management.
- **Haptics**: Targeted `HapticFeedback` (Light to Heavy) for every interaction—from button clicks to successful payment confirmation.

---

## 🏗 Directory Structure

```text
lib/
├── core/
│   ├── bloc/               # Global Auth & App State
│   ├── models/             # Unified API Data Models
│   ├── services/           # Payment, API, & Notification Logic
│   └── widgets/            # Premium UI Components (Cards, Buttons)
├── features/
│   ├── auth/               # OTP & Registration Flow
│   ├── home/               # Product Discovery
│   ├── product/            # Plan Selection & Application Detail
│   ├── orders/             # Dashboard & Filter Management
│   ├── track/              # Real-time Status & Lifecycle
│   └── claims/             # Claims Submission & Tracking
└── main.dart               # Entry Point & Global Provider Setup
```

---

## 🔒 Installation & Setup

1. **Clone the Project**:
   ```bash
   git clone https://github.com/your-repo/digipe.git
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Android Configuration**:
   - Ensure your `minSdkVersion` is 21 or higher.
   - For biometrics, ensure the user has enrolled at least one fingerprint/face on their device.

4. **Run the App**:
   ```bash
   flutter run
   ```

---

## 🎨 Design Language
DIGIPe follows a **"Dark Premium"** aesthetic:
- **Primary Color**: Ink Black (`#111111`)
- **Accent Color**: Emerald Green (`#238643`) for success/payments.
- **Typography**: `Poppins` (Weights 400-800) for a modern, trustworthy feel.
- **Elevation**: Soft, low-alpha shadows (`alpha: 0.035`) and large border radii (`20px - 28px`) for a contemporary mobile-first look.

---

## 📄 License
© 2026 DIGIPe India. All rights reserved. Made with ❤️ for the sustainable energy revolution.
