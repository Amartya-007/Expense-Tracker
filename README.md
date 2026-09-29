# 💰 RupeeCommand — Personal Money Command Center

A high-performance, privacy-focused, offline-first personal expense and money manager built with Flutter. Designed for real daily use on Android devices with complete support for edge-to-edge system navigation, multi-account liquid tracking, custom tags, and zero cloud dependency.

![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Framework](https://img.shields.io/badge/Framework-Flutter-02569B?logo=flutter&logoColor=white)
![Privacy](https://img.shields.io/badge/Data-100%25%20Local%20%26%20Private-success)

---

## 🚀 Key Highlights & Architectural Changes

### 1. 🚀 Direct App Launch
- First launch opens a guided onboarding flow: name is required, while accounts, categories, tags, budgets, and SMS capture are optional.
- After onboarding, the app opens directly into the main navigation.
- No PIN or biometric authentication prompt is shown during startup.

### 2. 📩 Automatic SMS Expense Capture
- Android transaction SMS alerts can be enabled from onboarding or Settings.
- Recognized debit and credit alerts are parsed and added once as local `autoCaptured` transactions.
- OTPs and promotional messages are ignored, and stable message IDs prevent duplicate expenses.
- The current implementation handles standard Android SMS broadcasts; RCS/notification access is not enabled.

### 3. 🧹 Zero Seed Data & Clean Slate Architecture
- **Clean Slate**: Removed all sample/dummy transactions, mock accounts, fake budgets, and dummy goals.
- **Fresh Start**: The app starts with a default baseline wallet (Cash Wallet, ₹0 balance) and default editable categories.
- **Data Reset**: A dedicated **Clear All Data (Clean Slate)** option in Settings allows instant wiping of all accounts and records at any time.

### 4. 🏷️ Full Custom Tag Management
- **Dedicated Tags Screen**: Access **Manage Tags** from the More Hub (`Icons.tag_rounded`).
- **Full CRUD**: Create, rename, and delete custom tags. Displays real-time transaction usage counts.
- **Inline Tag Creation**: Create and apply new tags directly inside the Add/Edit Transaction sheet without leaving your workflow.

### 5. 🗂️ Complete CRUD on Accounts & Categories
- **Accounts**: Add, edit, or delete Cash, Bank, UPI, Credit Card, and Loan accounts with balance tracking and account number masking.
- **Categories & Subcategories**: Add, rename, or delete Expense and Income categories. Add and delete individual subcategories directly.

### 6. 📱 Android System UI & Safe Area Compliance
- **No Native Navigation Clashes**: Added generous bottom padding (88-100dp) across all scrollable screens (`HomeScreen`, `TransactionsScreen`, `BudgetsScreen`, `InsightsScreen`, `MoreScreen`, `AccountsScreen`, `CategoriesScreen`, `TagsScreen`, `AddTransactionSheet`).
- **Safe Area Insets**: Dialogs, bottom sheets, and FABs respect `MediaQuery.viewInsets` and `MediaQuery.padding.bottom` so no button or list item is ever cut off by Android 3-button or gesture navigation bars.
- **Clean Navigation UI**: Streamlined to a 5-tab Material 3 `NavigationBar` with dedicated floating action button, replacing cramped 6-icon layouts.

---

## 📱 Navigation Structure (5 Core Tabs)

1. 🏠 **Home** — Real-time liquid balance, monthly income vs. expense progress, category summaries, upcoming bills, and quick insights.
2. 📋 **Transactions** — Chronological transaction history grouped by date, daily net totals, search, filter by account/type/category.
3. 📊 **Budgets** — Category budgets with visual progress indicators, safe spending limits, and burn rates.
4. 📈 **Insights** — Financial health analytics, category breakdowns, merchant rankings, and monthly compare charts.
5. ⚙️ **More Hub** — Profile, Accounts, Savings Goals, Recurring Bills, SMS Review Queue, Receipts Gallery, Shared Expenses, Categories, Tags, and Settings.

---

## 🛠️ Tech Stack & Dependencies

| Component | Specification |
|---|---|
| Framework | Flutter 3.x (Dart 3.x) |
| Architecture | Provider Pattern (`ChangeNotifier`) |
| Local Persistence | SharedPreferences (JSON serialized) |
| Visual Charts | `fl_chart` |
| Image Picker | `image_picker` |
| Design Language | Material 3 with tailored Dark/Light HSL palettes |

---

## 📲 How to Install the App on Your Phone

### Option A: Direct Install via USB Debugging (Recommended)

1. **Enable Developer Options on Phone**:
   - Go to phone **Settings** → **About Phone**.
   - Tap **Build Number** 7 times until you see *"You are now a developer!"*.
2. **Enable USB Debugging**:
   - Go to **Settings** → **System / Additional Settings** → **Developer Options**.
   - Turn on **USB Debugging**.
3. **Connect Phone to PC**:
   - Connect your phone using a USB data cable.
   - On your phone, tap **Allow USB debugging** (check "Always allow from this computer").
4. **Verify ADB Connection**:
   ```bash
   adb devices
   ```
   You should see your device ID with the status `device`.
5. **Install and Launch**:
   ```bash
   # From the project directory:
   flutter run -d <your-device-id>
   # OR install the prebuilt APK directly:
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

### Option B: Sideloading the APK Manually

1. Build the APK:
   ```bash
   flutter build apk --debug
   ```
2. The APK will be ready at:
   ```
   expensetracker/build/app/outputs/flutter-apk/app-debug.apk
   ```
3. Transfer `app-debug.apk` to your phone via USB file transfer, Google Drive, WhatsApp, or Quick Share.
4. On your phone, tap `app-debug.apk` to install (allow "Install from unknown sources" if prompted).

---

## 🔒 Security & Privacy Features

- **100% Offline**: No network calls, no cloud servers, no analytics trackers. Your data never leaves your device.
- **Privacy Mode**: Tap the eye icon in the top header to mask all monetary values with `₹••••••` when in public.

---

## 📁 Project File Layout

```
lib/
├── main.dart                          # App initialization & route bootstrap
├── theme/
│   └── app_theme.dart                 # Color tokens, elevation, Material 3 theme
├── providers/
│   └── app_state.dart                 # Central AppState with full CRUD & reactive notifications
├── services/
│   ├── database_service.dart           # Local SharedPreferences persistence engine
│   ├── sms_capture_service.dart        # Flutter bridge for native SMS capture
│   └── sms_parser_service.dart         # Transaction SMS parsing heuristics
├── models/
│   ├── account.dart                   # Account and liability definitions
│   ├── category.dart                  # Categories & subcategories
│   ├── transaction.dart               # Transactions, splits, receipts, tags
│   ├── budget.dart                    # Category budgets
│   ├── goal.dart                      # Savings goals
│   ├── recurring_bill.dart            # Subscriptions and recurring bills
│   └── user_profile.dart              # User profile and preferences
├── screens/
│   ├── splash/splash_screen.dart      # Launch screen and route bootstrap
│   ├── main_navigation_screen.dart    # 5-tab Material 3 bottom navigation
│   ├── home/home_screen.dart          # Money dashboard
│   ├── transactions/                  # Transactions list, search, split, details
│   ├── add_transaction/               # Add/Edit record sheet with inline tag creation
│   ├── budgets/budgets_screen.dart    # Category budgets & safe spending
│   ├── insights/insights_screen.dart  # Trends & breakdown charts
│   ├── categories/categories_screen.dart # Manage categories & subcategories
│   ├── accounts/accounts_screen.dart  # Manage bank & cash accounts
│   ├── tags/tags_screen.dart          # Dedicated Tag management screen
│   ├── profile/profile_screen.dart    # Profile and preferences
│   ├── settings/settings_screen.dart  # System settings, clean slate & export
│   └── more/more_screen.dart          # More hub navigation
└── utils/
    ├── currency_formatter.dart        # Rupee formatting with privacy masking
    └── voice_parser.dart              # Natural language offline voice expense parser
```

---

*Built with ❤️ for privacy-conscious personal money management.*
