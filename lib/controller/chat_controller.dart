import 'dart:io';

import 'package:app_limiter/app_limiter.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:discipline_mind/controller/alert_controller.dart';
import 'package:discipline_mind/model/chat_message_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/app_block_preferences_service.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final NativeAppBlockService _blockService = NativeAppBlockService();
  final AppBlockPreferencesService _prefs = AppBlockPreferencesService();

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;

  List<String> _selectedBlockedPackages() {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      return blockedTradingAppPackages;
    }
    return _prefs.getSelectedPackages(userId: userId);
  }

  @override
  void onInit() {
    super.onInit();
    loadMessages();
  }

  /// Fetch messages from API
  /// [refresh] - use isRefreshing (pull-to-refresh indicator)
  /// [silent] - no loader at all, use when e.g. notification received
  Future<void> loadMessages({bool refresh = false, bool silent = false}) async {
    if (!silent) {
      if (refresh) {
        isRefreshing.value = true;
      } else {
        isLoading.value = true;
      }
    }

    try {
      final userId = Common.userData.value?.payload?.id?.toString() ?? '2';
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.postMessagesForm(ApiUrl.getMessagesByUser, {
        'user_id': userId,
      });

      if (response.isSuccess && response.data != null) {
        final payload = response.data['payload'];
        if (payload is List) {
          final parsed = <ChatMessage>[];
          for (final item in payload) {
            if (item is Map<String, dynamic>) {
              // We reverse at the end for oldest->newest display, so reverse
              // each item's parsed messages here to preserve local order.
              parsed.addAll(chatMessagesFromJson(item).reversed);
            }
          }
          // API returns newest first; chat shows oldest first
          final chronological = parsed.reversed.toList();
          final display = _dedupeRedundantDeleteTradeButtons(chronological);
          messages.assignAll(display);
          await _syncDefaultBlockingByOpportunity(display);
        }
      } else {
        if (!refresh) {
          _loadSampleMessages();
        }
        if (response.errorMessage != null) {
          AppToast.showToast(response.errorMessage!);
        }
      }
    } catch (e) {
      if (!refresh && !silent) _loadSampleMessages();
      if (!silent) AppToast.showToast('Failed to load chat: $e');
    } finally {
      if (!silent) {
        isLoading.value = false;
        isRefreshing.value = false;
      }
    }
  }

  /// Keep apps blocked by default until a fresh opportunity (action=add) exists.
  Future<void> _syncDefaultBlockingByOpportunity(
    List<ChatMessage> display,
  ) async {
    if (!Platform.isAndroid) return;
    try {
      final hasNewOpportunity = display.any((m) {
        if (m is! NewTradeOpportunityMessage) return false;
        final action = m.action.toLowerCase().trim();
        return action.isEmpty || action == 'add';
      });
      final selectedPackages = _selectedBlockedPackages();
      if (selectedPackages.isEmpty) return;

      if (hasNewOpportunity) {
        for (final package in selectedPackages) {
          await _blockService.unblockApp(package);
        }
        await _blockService.unblockAndClose(selectedPackages);
        await _blockService.stopBlockingService();
      } else {
        final userId = Common.userData.value?.payload?.id?.toString();
        if (userId != null && userId.isNotEmpty) {
          await _blockService.saveUserIdForOverlay(userId);
        }
        for (final package in selectedPackages) {
          await _blockService.blockApp(package);
        }
        await _blockService.startBlockingService();
      }
    } catch (e) {
      print('[ChatController] _syncDefaultBlockingByOpportunity failed: $e');
    }
  }

  /// If the same trade has both `open_app_button` and `delete_button`, the UI
  /// already shows one combined bubble — drop the redundant `delete_button` row.
  List<ChatMessage> _dedupeRedundantDeleteTradeButtons(
    List<ChatMessage> chronological,
  ) {
    final openAppDeleteTradeIds = <String>{};
    for (final m in chronological) {
      if (m is! NewTradeOpportunityMessage) continue;
      if (m.buttonType != 'open_app_button') continue;
      if (m.action.toLowerCase() != 'delete') continue;
      if (m.tradeId.isEmpty) continue;
      openAppDeleteTradeIds.add(m.tradeId);
    }
    return chronological.where((m) {
      if (m is! NewTradeOpportunityMessage) return true;
      if (m.buttonType != 'delete_button') return true;
      if (m.action.toLowerCase() != 'delete') return true;
      if (m.tradeId.isEmpty) return true;
      return !openAppDeleteTradeIds.contains(m.tradeId);
    }).toList();
  }

  void _loadSampleMessages() {
    messages.assignAll([
      const SimpleTextMessage(text: 'Hello'),
      const SimpleTextMessage(text: 'I am Monkk AI Agent.'),
      const SimpleTextMessage(text: 'Hi', isFromUser: true),
      const SimpleTextMessage(text: 'Hi'),
    ]);
  }

  void addMessage(ChatMessage msg) {
    messages.add(msg);
    if (msg is TradeExecutedMessage) {
      onTradeExecuted();
    }
  }

  void sendTextMessage(String text) {
    if (text.trim().isEmpty) return;
    addMessage(SimpleTextMessage(text: text.trim(), isFromUser: true));
  }

  /// Called when user submits trade params from New Trade Opportunity popup.
  /// Blocks trading apps (Zerodha, Upstox, Groww).
  Future<void> onSubmitTradeParams({
    required String stopLoss,
    required String entry,
    required String frr,
    required String instrument,
    required String contract,
  }) async {
    try {
      if (Platform.isAndroid) {
        final userId = Common.userData.value?.payload?.id?.toString();
        if (userId != null) {
          await _blockService.saveUserIdForOverlay(userId);
        }
        final perms = await _blockService.checkPermissions();
        if (perms['hasOverlayPermission'] != true) {
          await _blockService.requestOverlayPermission();
        }
        if (perms['hasUsageStatsPermission'] != true) {
          await _blockService.requestUsageStatsPermission();
        }
        final selectedPackages = _selectedBlockedPackages();
        for (final package in selectedPackages) {
          await _blockService.blockApp(package);
        }
        try {
          await _blockService.startBlockingService();
        } catch (e) {
          print('[ChatController] startBlockingService failed: $e');
        }
        AppToast.showToast('Trading apps have been locked');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        final granted = await limiter.requestIosPermission();
        if (granted) {
          await limiter.blockAndUnblockIOSApp();
          AppToast.showToast('Trading apps have been locked');
        } else {
          AppToast.showToast('iOS permission required to block apps');
        }
      }
    } catch (e) {
      AppToast.showToast('Error: $e');
    }
  }

  /// Default GTT price parsed from entry range (e.g. "390 - 400" -> "390").
  static String getDefaultGttPrice(String entryRange) {
    final match = RegExp(r'[\d.]+').firstMatch(entryRange);
    return match?.group(0) ?? '';
  }

  /// true => selected app needs GTT + SL + Target in popup.
  bool shouldUseExtendedGttInputs() {
    final selected = _selectedBlockedPackages();
    return selected.any(extendedGttInputPackages.contains);
  }

  /// Create GTT alert via API. Refreshes messages from backend on success.
  Future<bool> createGttAlert(
    NewTradeOpportunityMessage msg,
    String gttPrice, {
    String? stopLoss,
    String? takeProfit,
  }) async {
    if (gttPrice.trim().isEmpty) {
      AppToast.showToast('Please enter GTT price');
      return false;
    }
    try {
      final hasPermissions = await _checkBlockAppPermissions();
      if (!hasPermissions) {
        // Permission denied: do not call GTT create API.
        return false;
      }

      final userId = Common.userData.value?.payload?.id?.toString() ?? '2';
      final instrument = msg.exchange.isNotEmpty
          ? '${msg.exchange}:${msg.instrument}'
          : msg.instrument;
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final fields = <String, String>{
        'user_id': userId,
        'instrument': instrument,
        'gtt_price': gttPrice.trim(),
        'trade_id': msg.tradeId,
      };
      if (stopLoss != null && stopLoss.trim().isNotEmpty) {
        fields['stop_loss'] = stopLoss.trim();
        // Optional compatibility key for backends aligned with alert schema.
        fields['lower_price'] = stopLoss.trim();
      }
      if (takeProfit != null && takeProfit.trim().isNotEmpty) {
        fields['take_profit'] = takeProfit.trim();
        // Optional compatibility key for backends aligned with alert schema.
        fields['upper_price'] = takeProfit.trim();
      }
      final response = await api.postFormData(ApiUrl.gttAlertCreate, fields);
      if (response.isSuccess) {
        await _applyTradingAppBlock(userId);
        AppToast.showToast('GTT alert created successfully');
        loadMessages(refresh: true);
        return true;
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Failed to create GTT alert',
        );
        return false;
      }
    } catch (e) {
      AppToast.showToast('Error: $e');
      return false;
    }
  }

  Future<bool> _checkBlockAppPermissions() async {
    if (Platform.isIOS) {
      final limiter = AppLimiter();
      final granted = await limiter.requestIosPermission();
      if (!granted) {
        AppToast.showToast('iOS ScreenTime permission required');
        return false;
      }
      return true;
    }

    final permissions = await _blockService.checkPermissions();
    final overlayGranted = permissions['hasOverlayPermission'] ?? false;
    final usageGranted = permissions['hasUsageStatsPermission'] ?? false;

    if (!overlayGranted) {
      await _blockService.requestOverlayPermission();
    }
    if (!usageGranted) {
      await _blockService.requestUsageStatsPermission();
    }

    final updated = await _blockService.checkPermissions();
    final granted =
        (updated['hasOverlayPermission'] ?? false) &&
        (updated['hasUsageStatsPermission'] ?? false);
    if (!granted) {
      AppToast.showToast(
        'Android overlay and usage access permissions are required to create GTT alert',
      );
    }
    return granted;
  }

  Future<void> _applyTradingAppBlock(String? userId) async {
    if (Platform.isAndroid) {
      if (userId != null && userId.isNotEmpty) {
        await _blockService.saveUserIdForOverlay(userId);
      }
      final selectedPackages = _selectedBlockedPackages();
      for (final package in selectedPackages) {
        await _blockService.blockApp(package);
      }
      try {
        await _blockService.startBlockingService();
      } catch (e) {
        print('[ChatController] startBlockingService failed: $e');
      }
      AppToast.showToast('Trading apps have been locked');
      return;
    }

    if (Platform.isIOS) {
      try {
        final limiter = AppLimiter();
        await limiter.blockAndUnblockIOSApp();
        AppToast.showToast('Trading apps have been locked');
      } catch (e) {
        print('[ChatController] iOS block failed: $e');
      }
    }
  }

  /// Submit trade executed (entry, stop loss, take profit). Uses AlertController.
  Future<bool> submitTradeExecuted({
    required NewTradeOpportunityMessage msg,
    required String entryPrice,
    required String stopLoss,
    required String takeProfit,
  }) async {
    final alertController = Get.isRegistered<AlertController>()
        ? Get.find<AlertController>()
        : Get.put(AlertController(), permanent: true);
    final entry = double.tryParse(entryPrice) ?? 0.0;
    final instrument = msg.exchange.isNotEmpty
        ? '${msg.exchange}:${msg.instrument}'
        : msg.instrument;
    final success = await alertController.createTradeAlert(
      instrument: instrument,
      upperPrice: takeProfit,
      lowerPrice: stopLoss,
      currentPrice: entry,
      tradeId: msg.tradeId,
    );
    if (success) {
      loadMessages(refresh: true);
    }
    return success;
  }

  /// POST `delete/trade` (trade_id + user_id) after user taps Trade Deleted.
  Future<void> acknowledgeTradeDeleted(NewTradeOpportunityMessage msg) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      AppToast.showToast('Please sign in to confirm');
      return;
    }
    if (msg.tradeId.isEmpty) {
      AppToast.showToast('Missing trade id');
      return;
    }
    try {
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.postFormData(ApiUrl.deleteTrade, {
        'trade_id': msg.tradeId,
        'user_id': userId,
      });
      if (response.isSuccess) {
        AppToast.showToast('Trade deleted');
        await loadMessages(refresh: true);
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Could not record trade deletion',
        );
      }
    } catch (e) {
      AppToast.showToast('Error: $e');
      print('[ChatController] acknowledgeTradeDeleted failed: $e');
    }
  }

  /// POST `edit/trade` (trade_id + user_id) after user taps SL Trailed.
  Future<void> acknowledgeSlTrailed(NewTradeOpportunityMessage msg) async {
    final userId = Common.userData.value?.payload?.id?.toString();
    if (userId == null || userId.isEmpty) {
      AppToast.showToast('Please sign in to confirm');
      return;
    }
    if (msg.tradeId.isEmpty) {
      AppToast.showToast('Missing trade id');
      return;
    }
    try {
      final api = Get.isRegistered<ApiService>()
          ? Get.find<ApiService>()
          : Get.put(ApiService(), permanent: true);
      final response = await api.postFormData(ApiUrl.editTrade, {
        'trade_id': msg.tradeId,
        'user_id': userId,
      });
      if (response.isSuccess) {
        AppToast.showToast('SL trailed');
        await loadMessages(refresh: true);
      } else {
        AppToast.showToast(
          response.errorMessage ?? 'Could not record SL trail confirmation',
        );
      }
    } catch (e) {
      AppToast.showToast('Error: $e');
      print('[ChatController] acknowledgeSlTrailed failed: $e');
    }
  }

  /// Unblock trading apps and open the first selected broker app (Android).
  Future<void> openTradingApp() async {
    try {
      if (Platform.isAndroid) {
        final selectedPackages = _selectedBlockedPackages();
        for (final package in selectedPackages) {
          await _blockService.unblockApp(package);
        }
        // Overlay channel can be absent in some builds; launch should still proceed.
        await _blockService.unblockAndClose(selectedPackages);
        await _blockService.stopBlockingService();
        var launched = false;
        for (final package in selectedPackages) {
          final aliases = tradingAppLaunchAliases[package] ?? [package];
          for (final candidate in aliases) {
            final ok = await _blockService.launchApp(candidate);
            if (ok) {
              launched = true;
              break;
            }
          }
          if (launched) {
            break;
          }
        }
        if (!launched) {
          AppToast.showToast('Selected trading app is not installed/enabled');
        }
        AppToast.showToast('Trading apps unlocked');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        await limiter.blockAndUnblockIOSApp();
        AppToast.showToast('Trading apps unlocked');
      }
    } catch (e) {
      print('[ChatController] openTradingApp failed: $e');
    }
  }

  /// Called when Trade Executed message is received. Unlocks trading apps.
  Future<void> onTradeExecuted() async {
    try {
      if (Platform.isAndroid) {
        final selectedPackages = _selectedBlockedPackages();
        for (final package in selectedPackages) {
          await _blockService.unblockApp(package);
        }
        await _blockService.unblockAndClose(selectedPackages);
        await _blockService.stopBlockingService();
        AppToast.showToast('Trading apps unlocked');
      } else if (Platform.isIOS) {
        final limiter = AppLimiter();
        await limiter.blockAndUnblockIOSApp();
        AppToast.showToast('Trading apps unlocked');
      }
    } catch (e) {
      print('[ChatController] onTradeExecuted failed: $e');
    }
  }
}
