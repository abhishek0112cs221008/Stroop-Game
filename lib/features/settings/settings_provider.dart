import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme Provider ─────────────────────────────────────────────────────────────

final _sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override SharedPreferences in ProviderScope');
});

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final prefs = ref.watch(_sharedPrefsProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier(this._prefs) : super(_prefs.getBool('dark_mode') ?? false);

  final SharedPreferences _prefs;
  static const _key = 'dark_mode';

  void toggle() {
    state = !state;
    _prefs.setBool(_key, state);
  }
}

// ── Notification Provider ──────────────────────────────────────────────────────

final notifEnabledProvider = StateNotifierProvider<NotifNotifier, bool>((ref) {
  final prefs = ref.watch(_sharedPrefsProvider);
  return NotifNotifier(prefs);
});

class NotifNotifier extends StateNotifier<bool> {
  NotifNotifier(this._prefs) : super(_prefs.getBool('notif_enabled') ?? false);

  final SharedPreferences _prefs;
  static const _key = 'notif_enabled';

  void setValue(bool v) {
    state = v;
    _prefs.setBool(_key, v);
  }
}

// ── Helper to expose SharedPreferences ────────────────────────────────────────

List<Override> buildProviderOverrides(SharedPreferences prefs) => [
  _sharedPrefsProvider.overrideWithValue(prefs),
];
