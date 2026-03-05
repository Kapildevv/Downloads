# Howealthy App Folder & File Structure

This document describes the entire folder structure and key files of the `howealthy1` Flutter app. You can provide this to ChatGPT to determine what to keep, move, or refactor.

## 1. Root Level Directories & Files
*   **`.dart_tool/`, `.idea/`, `.vscode/`, `build/`**: Auto-generated IDE settings and build artifacts. *(Generally safe to ignore or delete when migrating; they will be regenerated).*
*   **`android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/`**: Platform-specific native configuration and runner code. *(Keep these unless you plan to create a fresh Flutter project and migrate only the `lib` folder).*
*   **`assets/`**: Contains static assets like images, icons, and fonts. *(Keep)*.
*   **`docs/`**: Project documentation. *(Keep)*.
*   **`lib/`**: The core directory containing all the Dart source code for the app. *(Keep — see breakdown below)*.
*   **`test/`**: Contains unit and widget tests for the app. *(Keep)*.
*   **`pubspec.yaml`, `pubspec.lock`**: Defines the project dependencies and their locked versions. *(Keep/Merge carefully)*.
*   **`analysis_options.yaml`**: Dart static analysis and linting rules. *(Keep)*.
*   **`firebase-key.json`**: Sensitive service account key for Firebase. *(**CRITICAL:** Keep secure, DO NOT share contents with ChatGPT!)*.
*   **`firestore.rules`, `storage.rules`**: Firebase security and storage rules. *(Keep)*.
*   **`README.md`, `ceo_board.md`**: Project-level Markdown documentation and CEO tracking board. *(Keep)*.
*   **`l10n.yaml`**: Localization configuration pointing to `.arb` files. *(Keep)*.
*   **Helper Scripts (`add_l10n_key.py`, `replace_colors.py`, `fix_colors_2.py`)**: Utility Python scripts used for refactoring. *(Keep if still useful)*.
*   **Text/Log Files (`analyze.txt`, `errors.txt`, `test_output.txt`, etc.)**: Logs from previous analysis or debug sessions. *(Safe to delete)*.

---

## 2. The `lib/` Directory (Core App Code)

### `lib/main.dart`
The main entry point of the Flutter applications. Handles app initialization, theme injection, and root routing.

### `lib/constants/`
*   `app_strings.dart`: Holds hardcoded strings or constant textual values used in the UI.

### `lib/l10n/`
Handles multiple languages (English, Hindi, Kannada, Tamil, Telugu).
*   Contains standard `.arb` translation files (e.g., `app_en.arb`, `app_hi.arb`).
*   Contains the generated `app_localizations.dart` Dart classes.

### `lib/models/`
Data structures and domain objects.
*   `expense_prediction.dart`, `fire_model.dart`, `fund_holding.dart`, `insight.dart`, `net_worth_item.dart`, `net_worth_summary.dart`, `parsed_expense.dart`, `spending_categories.dart`.

### `lib/providers/`
State management (likely Riverpod, Provider, or equivalent).
*   `analytics_providers.dart`: State for analytics and tracking.
*   `chat_state.dart`, `oracle_state.dart`: State for the Gemini AI/Oracle chat features.
*   `referral_providers.dart`: State for user referrals.
*   `data_pipeline.dart`: Manages data hydration and synchronization state.

### `lib/repositories/`
Data access layer (handles direct interactions with Firebase/Firestore and local Hive storage).
*   `alert_repository.dart`, `base_repository.dart`, `fire_repository.dart`, `mutual_fund_repository.dart`, `net_worth_repository.dart`, `transaction_repository.dart`, `user_repository.dart`.

### `lib/screens/`
The UI pages and views of the application.
*   **Key Pages**: `alert_scheduler_page.dart`, `biometric_guard.dart` (security layer), `fire_calculator_page.dart` (FIRE math UI), `login_page.dart`, `net_worth_dashboard_page.dart`, `oracle_chat_page.dart`, `profile_page.dart`, `send_report_page.dart`, `settings_page.dart`, `welcome_page.dart`, `whatsapp_setup_page.dart`.
*   **Subdirectories**:
    *   `mutual_funds/`: UI specific to mutual fund tracking.
    *   `views/`: Reusable, distinct view segments (often used within pages).
    *   `widgets/`: Smaller, reusable Flutter widgets (buttons, cards, inputs).

### `lib/services/`
Business logic, third-party integrations, and complex background services.
*   **AI & Analytics**: `analytics_engine.dart`, `clairvoyance_engine.dart`, `spending_analyzer.dart`, `gemini_service.dart`, `ml_classifier_service.dart`, `expense_predictor.dart`, `nl_expense_parser.dart`.
*   **Core Logic**: `fire_calculator_service.dart`, `nav_fetch_service.dart` (fetches mutual fund NAVs), `sip_tracker_service.dart`, `ingestion_engine.dart`.
*   **Security & Storage**: `encryption_service.dart`, `secure_storage_service.dart`, `pin_service.dart`.
*   **Growth & Notifications**: `deep_link_service.dart`, `growth_metrics_service.dart`, `milestone_service.dart`, `referral_service.dart`, `whatsapp_bot_service.dart`.

### `lib/theme/`
Styling constants and design system definitions.
*   `app_colors.dart`, `app_spacing.dart`, `app_theme.dart` (ThemeData definitions), `app_typography.dart`.
