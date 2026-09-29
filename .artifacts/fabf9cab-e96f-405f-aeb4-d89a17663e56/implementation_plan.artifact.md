# Advanced Expense Tracker Enhancement - Implementation Plan

Enhance the existing Expense Tracker application with advanced analytics, smart capture automation (SMS background listener, custom regex rules, voice-powered quick add), UI/UX improvements (haptic feedback, swipe gestures, custom accent color system), robust database persistence, comprehensive auditing, and thorough testing.

## User Review Required

> [!IMPORTANT]
> - **SMS Background Listener**: Relies on Android SMS permissions and background method channels (`expensetracker/sms`). If permissions are denied or unavailable, it degrades gracefully.
> - **Voice-Powered Quick Add**: Integrates speech recognition (using `speech_to_text` package or robust fallback) with voice parsing.
> - **Custom Accent Colors**: Adds accent color selection in Settings supporting both light and dark modes with semantic color tokens.
> - **Database Migrations**: Adds new tables for custom parser rules, anomaly metadata, and user preferences without destructive changes to existing tables.

## Proposed Changes

### 1. Advanced Financial Analytics & Insights (`SpendingAnalyticsService`)
- **[NEW] [spending_analytics_service.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/services/spending_analytics_service.dart)**:
  - Rolling historical average calculator, anomaly detector, fixed vs. discretionary classification, and savings velocity projection.
- **[MODIFY] [insights_screen.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/screens/insights/insights_screen.dart)**:
  - Add anomaly alerts section, fixed vs. discretionary breakdown, and savings velocity projection chart.

### 2. Automation and Smart Capture
- **[MODIFY] [sms_capture_service.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/services/sms_capture_service.dart)** & **[sms_parser_service.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/services/sms_parser_service.dart)**:
  - Enhance background SMS polling/listening and rule-based parsing.
- **[NEW] [custom_rules_repository.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/features/transactions/data/custom_rules_repository.dart)** & **[parser_rules_screen.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/screens/settings/parser_rules_screen.dart)**:
  - Custom regex and keyword rule builder settings screen with validation.
- **[MODIFY] [voice_parser.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/utils/voice_parser.dart)** & **[quick_add_sheet.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/screens/add_transaction/quick_add_sheet.dart)**:
  - Enhance voice-powered quick add with speech-to-text integration and transaction draft review queue.

### 3. UI/UX Improvements
- **[NEW] [haptic_service.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/services/haptic_service.dart)**:
  - Centralized haptic feedback service respecting settings.
- **[MODIFY] [transactions_screen.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/screens/transactions/transactions_screen.dart)** & transaction list widgets:
  - Add intuitive swipe left (delete/archive) and swipe right (edit/review) gestures with confirmation.
- **[MODIFY] [app_theme.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/theme/app_theme.dart)** & **[app_state.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/providers/app_state.dart)**:
  - Implement custom accent color system with dynamic theme generation, persistence, and support for light/dark modes.

### 4. Database, Audit, and Testing
- **[MODIFY] [app_database.dart](file:///C:/Users/Windows_11/OneDrive/Desktop/Expense-Tracker/expensetracker/lib/core/database/app_database.dart)**:
  - Add tables for `custom_parser_rules`, `anomaly_metadata`, and user preference columns.
- **[MODIFY] audit_log_service.dart & repositories**:
  - Integrate audit logging for all new automation, anomaly detection, rule changes, and voice actions.
- **[NEW] Unit & Widget Tests**:
  - Add tests for anomaly detection, recurring classification, savings projection, SMS parsing, custom rules, voice parsing, and theme switching.

## Verification Plan

### Automated Tests
- Run `flutter test` to verify unit and widget tests.

### Manual Verification
- Test anomaly detection alerts in Insights.
- Test custom regex rules creation and testing in Transaction Parsing Rules settings.
- Test voice quick add with speech input simulation.
- Test haptics toggle and swipe gestures on transaction lists.
- Test custom accent colors across light and dark modes.
