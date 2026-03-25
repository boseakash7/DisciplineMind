import 'dart:io';

import 'package:app_limiter/app_limiter.dart';
import 'package:discipline_mind/common/common.dart';
import 'package:discipline_mind/constants/blocked_apps.dart';
import 'package:discipline_mind/controller/alert_controller.dart';
import 'package:discipline_mind/model/chat_message_model.dart';
import 'package:discipline_mind/services/api/api_services.dart';
import 'package:discipline_mind/services/api/api_url.dart';
import 'package:discipline_mind/services/native_app_block_service.dart';
import 'package:discipline_mind/ui/widgets/app_toast.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final NativeAppBlockService _blockService = NativeAppBlockService();
  static const _blockedPackages = blockedTradingAppPackages;

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;

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
              parsed.add(chatMessageFromJson(item));
            }
          }
          // API returns newest first; chat shows oldest first
          messages.assignAll(parsed.reversed);
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
        for (final package in _blockedPackages) {
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

  /// Create GTT alert via API. Refreshes messages from backend on success.
  Future<bool> createGttAlert(
    NewTradeOpportunityMessage msg,
    String gttPrice,
  ) async {
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
      final response = await api.postFormData(ApiUrl.gttAlertCreate, {
        'user_id': userId,
        'instrument': instrument,
        'gtt_price': gttPrice.trim(),
      });
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
    final granted = (updated['hasOverlayPermission'] ?? false) &&
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
      for (final package in _blockedPackages) {
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
    );
    if (success) {
      loadMessages(refresh: true);
    }
    return success;
  }

  /// Called when Trade Executed message is received. Unlocks trading apps.
  Future<void> onTradeExecuted() async {
    try {
      if (Platform.isAndroid) {
        for (final package in _blockedPackages) {
          await _blockService.unblockApp(package);
        }
        await _blockService.unblockAndClose(_blockedPackages);
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
