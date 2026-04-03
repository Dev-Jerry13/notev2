# 📝 Samsung Notes — Premium Flutter App

A fully-featured, premium note-taking application inspired by Samsung Notes, built with Flutter. Delivers a fluid, modern experience with smooth animations, rich text editing, local persistence, and a polished Material 3 UI.

---

## ✨ Features

### Core
- ✅ Create, edit, delete, and view notes
- ✅ Rich text formatting (bold, italic, underline, bullet/numbered lists)
- ✅ Created and updated timestamps + word count
- ✅ Notes preview cards with truncated content

### Storage
- ✅ **Hive** local database — fast binary reads/writes
- ✅ Full persistence across app restarts
- ✅ Structured models with type-safe adapters

### File & Media
- ✅ Attach `.txt`, `.pdf`, `.doc/.docx` files via `file_picker`
- ✅ Inline image attachments from gallery or camera via `image_picker`
- ✅ Files copied to app documents directory for persistence
- ✅ Image grid preview inside notes

### UI/UX
- ✅ **Hero transitions** — note card → editor (shared element animation)
- ✅ **Slide + fade transitions** — smooth screen navigation
- ✅ **Staggered list animations** — cards animate in with delay offsets
- ✅ **AnimatedContainer** — color changes, selection states
- ✅ **AnimatedSwitcher** — title ↔ selection mode toggle
- ✅ **SizeTransition** — formatting toolbar slides in/out
- ✅ **ScaleTransition** — FAB entrance animation
- ✅ **Implicit animations** — press feedback via `AnimationController`
- ✅ **Bouncing scroll physics** — native-feel scrolling
- ✅ Haptic feedback on interactions
- ✅ Ripple touch effects throughout

### Screens
1. **Home Screen** — Grid/list view toggle, search bar, filter chips, pinned section
2. **Editor Screen** — Full-height editor, formatting toolbar, attachment panel, auto-save
3. **Search Screen** — Real-time search with tag cloud
4. **Settings Screen** — Dark mode toggle, statistics
5. **Trash Screen** — Restore/permanent delete with swipe gestures
6. **Folders Screen** — Create and manage folders with emoji icons

### Advanced
- ✅ Pin important notes (pinned float to top)
- ✅ Folder/category organization
- ✅ Tagging system with tag search
- ✅ **Auto-save** with 1.5s debounce while typing
- ✅ **Swipe to delete** (with undo snackbar)
- ✅ Swipe to restore in trash
- ✅ Note color accents (7 colors)
- ✅ **Export as .txt** via share sheet
- ✅ **Export as PDF** via share sheet
- ✅ Lock notes (UI ready, hash-based)
- ✅ Multi-select with batch delete
- ✅ Empty trash

### Dark Mode
- ✅ Full dark/light theme support
- ✅ Animated theme switching (350ms easing)
- ✅ Note colors adapt to theme (lighter in light, darker in dark)

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry, ProviderScope, MaterialApp
├── models/
│   ├── note_model.dart          # NoteModel, NoteAttachment, FolderModel, NoteColor
│   └── note_model.g.dart        # Hive TypeAdapters
├── providers/
│   └── notes_provider.dart      # Riverpod StateNotifiers + computed providers
├── services/
│   ├── storage_service.dart     # Hive CRUD wrapper
│   └── export_service.dart      # TXT + PDF export via share_plus
├── screens/
│   ├── home_screen.dart         # Notes grid/list, drawer, FAB
│   ├── editor_screen.dart       # Rich text editor, attachments, auto-save
│   ├── search_screen.dart       # Real-time search + tag browse
│   └── settings_screen.dart     # Settings + Trash + Folders screens
├── widgets/
│   └── note_card.dart           # NoteCard (grid), NoteListTile (list), TagChip
└── theme/
    └── app_theme.dart           # Light/dark ThemeData, AppColors, TextTheme
```

---

## 🎬 Animation System

| Animation | Technique | Location |
|-----------|-----------|----------|
| Note card → Editor | `Hero` widget with custom `flightShuttleBuilder` | `note_card.dart` → `editor_screen.dart` |
| Screen transitions | `PageRouteBuilder` with FadeTransition + SlideTransition | `home_screen.dart` |
| New note (slide up) | `PageRouteBuilder` with Offset(0, 0.08) slide | `home_screen.dart` |
| Card stagger | `flutter_animate` `.animate().fadeIn().slideY()` with index delay | `note_card.dart` |
| Press feedback | `AnimationController` + `ScaleTransition` (0.96 scale) | `note_card.dart` |
| Toolbar show/hide | `SizeTransition` driven by `FocusNode` listener | `editor_screen.dart` |
| FAB entrance | `ScaleTransition` on `AnimationController` | `home_screen.dart` |
| Title/selection swap | `AnimatedSwitcher` with fade | `home_screen.dart` |
| Theme switching | `MaterialApp.themeAnimationDuration = 350ms` | `main.dart` |
| Pin/color change | `AnimatedContainer(duration: 200ms)` | `note_card.dart` |
| View mode toggle | `AnimatedSwitcher` on icon | `home_screen.dart` |
| Empty state enter | `flutter_animate` `.fadeIn().scale()` | `home_screen.dart` |
| List items | `.animate().fadeIn().slideX()` with stagger | Various |

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0
- Android Studio / VS Code with Flutter extension
- Android SDK / Xcode (for target platform)

### 1. Install Flutter
Follow the [official Flutter install guide](https://docs.flutter.dev/get-started/install).

### 2. Clone / Create Project
```bash
# Create a new Flutter project
flutter create samsung_notes
cd samsung_notes

# Replace the generated files with the provided source files
```

### 3. Add Dependencies
Replace `pubspec.yaml` with the provided version, then:
```bash
flutter pub get
```

### 4. Add Custom Font (Optional but recommended)
The app references `SamsungOne`. To use a fallback:
- In `app_theme.dart`, change `fontFamily: 'SamsungOne'` to any Google Font
- Or add the font files to `assets/fonts/` and register in `pubspec.yaml`

Example with Google Fonts package:
```yaml
dependencies:
  google_fonts: ^6.2.1
```
Then in `app_theme.dart`:
```dart
import 'package:google_fonts/google_fonts.dart';
// Replace fontFamily: 'SamsungOne' with:
// textTheme: GoogleFonts.notoSansTextTheme(...)
```

### 5. Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

### 6. iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>To attach photos to notes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>To attach images from your gallery</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>To save note exports</string>
```

### 7. Run
```bash
# Check connected devices
flutter devices

# Run on device/emulator
flutter run

# Release build
flutter build apk --release
flutter build ios --release
```

---

## 📦 Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | ^2.5.1 | State management |
| `hive_flutter` | ^1.1.0 | Local storage |
| `flutter_animate` | ^4.5.0 | Stagger/entrance animations |
| `animations` | ^2.0.11 | Shared axis / material transitions |
| `flutter_staggered_grid_view` | ^0.7.0 | Masonry grid layout |
| `file_picker` | ^8.0.3 | File attachment |
| `image_picker` | ^1.1.2 | Image attachment |
| `pdf` | ^3.11.1 | PDF export |
| `share_plus` | ^9.0.0 | Native share sheet |
| `path_provider` | ^2.1.3 | App directories |
| `intl` | ^0.19.0 | Date formatting |
| `uuid` | ^4.4.0 | Unique IDs |

---

## 🎨 Design Philosophy

The app follows Samsung Notes' design language:
- **Clean cards** with subtle shadows, no borders in light mode
- **Typography-first** hierarchy — large bold title, smaller muted metadata
- **Contextual color** — 7 pastel note accent colors (dark variants in dark mode)
- **Breathing room** — generous padding, consistent 16px/20px gutters
- **Micro-interactions** — every tap has scale/haptic feedback
- **Zero visual noise** — icons only appear when needed

---

## 🔐 Note Locking

The lock feature stores a SHA-256 hash of the user's PIN. The current implementation shows the lock icon and prevents content preview. To complete the flow:
1. Show a PIN entry dialog when locking
2. Hash the PIN with `crypto` package: `sha256.convert(utf8.encode(pin)).toString()`
3. On unlock attempt, re-hash and compare

---

## 🐛 Troubleshooting

**Hive box already registered error:**
The type adapters use `isAdapterRegistered()` guards — this is handled automatically.

**File picker returns null on Android 13+:**
Ensure `READ_MEDIA_IMAGES` permission is in `AndroidManifest.xml`.

**Font not rendering:**
Remove `fontFamily: 'SamsungOne'` from `AppTheme` or provide the actual font files.
