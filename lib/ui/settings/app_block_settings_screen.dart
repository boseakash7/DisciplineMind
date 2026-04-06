import 'package:discipline_mind/common/app_colors.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/ui/main_home/main_home.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppBlockSettingsScreen extends StatefulWidget {
  const AppBlockSettingsScreen({super.key, this.isFirstSetup = false});

  final bool isFirstSetup;

  @override
  State<AppBlockSettingsScreen> createState() => _AppBlockSettingsScreenState();
}

class _AppBlockSettingsScreenState extends State<AppBlockSettingsScreen> {
  final AppBlockPreferencesService _prefs = AppBlockPreferencesService();
  final Set<String> _selected = <String>{};
  bool _isSaving = false;

  String? get _userId => Common.userData.value?.payload?.id?.toString();

  @override
  void initState() {
    super.initState();
    final userId = _userId;
    if (userId != null) {
      _selected.addAll(_prefs.getSelectedPackages(userId: userId));
    }
  }

  Future<void> _onSave() async {
    final userId = _userId;
    if (userId == null) {
      AppToast.showToast('User not found. Please login again.');
      return;
    }
    if (_selected.isEmpty) {
      AppToast.showToast('Please select at least one app');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _prefs.saveSelectedPackages(
        userId: userId,
        packages: _selected.toList(),
      );
      if (widget.isFirstSetup) {
        Get.offAll(() => const MainHomeScreen(initialIndex: 2));
      } else {
        AppToast.showToast('Blocked apps updated');
        Get.back();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isFirstSetup ? 'Select Apps to Block' : 'Blocked Apps';
    final subtitle = widget.isFirstSetup
        ? 'Choose apps to lock when trade is executed.'
        : 'Edit which apps should be locked on trade execution.';

    return WillPopScope(
      onWillPop: () async => !widget.isFirstSetup,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.isFirstSetup,
          title: Text(title),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: blockedTradingAppPackages.map((pkg) {
                      final selected = _selected.contains(pkg);
                      final label = blockedTradingAppLabels[pkg] ?? pkg;
                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: selected,
                          activeColor: AppColors.primary,
                          title: Text(label),
                          subtitle: Text(
                            pkg,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _selected.add(pkg);
                              } else {
                                _selected.remove(pkg);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isFirstSetup ? 'CONTINUE' : 'SAVE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

