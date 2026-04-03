// lib/utils/constants.dart

/// Hive box names
const String kNotesBox = 'notes';
const String kFoldersBox = 'folders';
const String kSettingsBox = 'settings';

/// Settings keys
const String kDarkModeKey = 'isDarkMode';
const String kViewModeKey = 'viewMode';
const String kDefaultFolderKey = 'defaultFolder';

/// Auto-save debounce duration (milliseconds)
const int kAutoSaveDelay = 1500;

/// Search debounce duration (milliseconds)
const int kSearchDebounce = 250;

/// Trash retention days
const int kTrashRetentionDays = 30;

/// Maximum tag length
const int kMaxTagLength = 30;

/// Maximum note title length
const int kMaxTitleLength = 200;

/// Maximum attachment size (10 MB)
const int kMaxAttachmentBytes = 10 * 1024 * 1024;

/// Supported file extensions for attachment
const List<String> kSupportedFileExtensions = [
  'txt', 'pdf', 'doc', 'docx',
];

const List<String> kSupportedImageExtensions = [
  'jpg', 'jpeg', 'png', 'gif', 'webp',
];

/// Animation durations
const Duration kShortAnim = Duration(milliseconds: 150);
const Duration kMedAnim = Duration(milliseconds: 250);
const Duration kLongAnim = Duration(milliseconds: 400);
const Duration kHeroAnim = Duration(milliseconds: 300);
const Duration kThemeAnim = Duration(milliseconds: 350);
