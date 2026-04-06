import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:get_storage/get_storage.dart';

class AppBlockPreferencesService {
  final GetStorage _box = GetStorage();

  String _selectedKey(String userId) => 'selected_blocked_apps_$userId';
  String _setupDoneKey(String userId) => 'blocked_apps_setup_done_$userId';

  List<String> getSelectedPackages({required String userId}) {
    final stored = _box.read<List<dynamic>>(_selectedKey(userId));
    final selected = stored?.map((e) => e.toString()).toList() ?? [];
    if (selected.isEmpty) {
      return List<String>.from(blockedTradingAppPackages);
    }
    return selected;
  }

  Future<void> saveSelectedPackages({
    required String userId,
    required List<String> packages,
  }) async {
    await _box.write(_selectedKey(userId), packages);
    await _box.write(_setupDoneKey(userId), true);
  }

  bool isSetupComplete({required String userId}) {
    final done = _box.read(_setupDoneKey(userId)) == true;
    final selected = _box.read<List<dynamic>>(_selectedKey(userId));
    return done && selected != null && selected.isNotEmpty;
  }
}

