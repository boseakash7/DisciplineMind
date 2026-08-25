import 'package:get_storage/get_storage.dart';

class AppBlockPreferencesService {
  final GetStorage _box = GetStorage();

  /// Single selected broker package (user picks one app).
  String _packageKey(String userId) => 'selected_blocked_app_package_$userId';

  /// Legacy: list of packages (migrated on read).
  String _legacyListKey(String userId) => 'selected_blocked_apps_$userId';

  String _setupDoneKey(String userId) => 'blocked_apps_setup_done_$userId';

  String? getSelectedPackage({required String userId}) {
    final stored = _box.read<String>(_packageKey(userId));
    if (stored != null && stored.isNotEmpty) return stored;

    final legacy = _box.read<List<dynamic>>(_legacyListKey(userId));
    if (legacy != null && legacy.isNotEmpty) {
      final first = legacy.first.toString();
      if (first.isNotEmpty) {
        _box.write(_packageKey(userId), first);
        return first;
      }
    }
    return null;
  }

  /// Non-empty list with at most one package (compat with block loops).
  List<String> getSelectedPackages({required String userId}) {
    final p = getSelectedPackage(userId: userId);
    if (p == null || p.isEmpty) return [];
    return [p];
  }

  Future<void> saveSelectedPackage({
    required String userId,
    required String packageName,
  }) async {
    await _box.write(_packageKey(userId), packageName);
    await _box.write(_setupDoneKey(userId), true);
    await _box.remove(_legacyListKey(userId));
  }

  bool isSetupComplete({required String userId}) {
    final done = _box.read(_setupDoneKey(userId)) == true;
    final pkg = getSelectedPackage(userId: userId);
    return done && pkg != null && pkg.isNotEmpty;
  }
}
